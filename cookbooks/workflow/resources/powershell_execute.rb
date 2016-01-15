require 'open3'
require_relative '../libraries/output_path.rb'

property :command, String, name_property: true
property :cwd, String, required: true
property :writer, LearnChef::Workflow::OutputPath, required: true

action :run do
  # Write the command to a temporary PowerShell script.
  script_path = File.join(cwd, 'temp.ps1')
  file script_path do
    content command
  end
  powershell_command = "powershell -File #{script_path}"
  stdout_str, stderr_str, status = Open3.capture3(powershell_command, chdir: cwd)
  file writer.stdout_path do
    content stdout_str
  end
  file writer.stderr_path do
    content stderr_str
  end
  file writer.status_path do
    content status.exitstatus.to_s
  end
  file writer.command_path do 
    content command
  end
end