require 'tempfile'

Puppet::Type.type(:gpg_key).provide(:gnupg) do

  def exists?
    return !get_fingerprint().nil?
  end

  def create
    data = []
    data.push("Key-Type: " + @resource.value(:keytype).to_s)
    data.push("Key-Length: " + @resource.value(:keylength).to_s)
    data.push("Name-Real: " + @resource.value(:uid).to_s)
    data.push("Expire-Date: " + @resource.value(:expire).to_s)
    data.push("%commit")

    stdin_data = data.join("\n") + "\n"
    self.debug "Generating key with data: \n#{stdin_data.strip}"

    passphrase = @resource.value(:passphrase)
    exec_gnupg(
      params: ['--generate-key'],
      stdin_data: stdin_data,
      raise_on_error: true,
      passphrase: passphrase,
    )
  end

  def destroy
    fpr = get_fingerprint()
    if !fpr.nil?
      exec_gnupg(
        params: ['--yes', '--delete-secret-and-public-key', fpr],
        raise_on_error: true,
      )
    end
  end

  def get_fingerprint
    ret = exec_gnupg(
      params: ['--with-colons', '--list-secret-keys', @resource.value(:uid)],
    )
    if ret[:exit_status] != 0
      self.debug "list-secret-keys exited with #{ret[:exit_status]}: #{ret[:stderr].strip}"
      return nil
    end

    ret[:stdout].each_line do |l|
      l.chomp!
      fields = l.split(':')
      if fields[0] != 'fpr'
        next
      end
      return fields[9]
    end
  end

  def get_public_key
    output = nil
    if fingerprint = get_fingerprint()
      ret = exec_gnupg(
        ['--export', '--export-options', 'export-minimal', '--armor', fingerprint],
        raise_on_error => true,
      )
      output = ret[:stdout]
    end
    return output
  end

  private
  def exec_gnupg(params:[], stdin_data:nil, raise_on_error:false, passphrase:'')
    stdin_r, stdin_w = IO.pipe
    stdout_r, stdout_w = IO.pipe
    stderr_r, stderr_w = IO.pipe
    pass_r, pass_w = IO.pipe

    if stdin_data
      stdin_w.write(stdin_data)
    end
    stdin_w.close

    pass_w.write(passphrase + "\n")
    pass_w.close

    child_pid = Kernel.fork do
      passphrase_args = ['--passphrase-fd', pass_r.fileno.to_s]

      command = [
        'gpg', '--batch', '--pinentry-mode', 'loopback'
      ] + passphrase_args + params

      self.debug "running gnupg command: #{command}"

      Process.setsid
      begin
        Puppet::Util::SUIDManager.change_privileges(resource[:owner], nil, true)
        # Clean environment
        Puppet::Util::POSIX::USER_ENV_VARS.each { |name| ENV.delete(name) }
        Puppet::Util::POSIX::LOCALE_ENV_VARS.each { |name| ENV.delete(name) }
        ENV['LANG'] = 'C'
        ENV['LC_ALL'] = 'C'
        Puppet::Util.withenv({}) do
          Kernel.exec(
            *command,
            :in => stdin_r,
            :out => stdout_w,
            :err => stderr_w,
            pass_r.fileno => pass_r,
          )
        end
      rescue => detail
        Puppet.log_exception(detail, "Could not execute command: #{detail}")
        exit!(1)
      end
    end
    stdin_r.close
    stdout_w.close
    stderr_w.close

    exit_status = Process.waitpid2(child_pid).last.exitstatus
    output = stdout_r.read()
    outerr = stderr_r.read()

    if raise_on_error and exit_status != 0
      raise Puppet::ExecutionFailure, "Execution of 'gpg #{params}' returned #{exit_status}: #{output.strip} (stderr: #{outerr.strip})"
    end

    return {
      :exit_status => exit_status,
      :stdout => output,
      :stderr => outerr,
    }
  end
end
