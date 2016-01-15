#
# Cookbook Name:: learn-the-basics-rhel
# Recipe:: _lesson2
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
# Configure a package and service
working_dir = File.join(ENV['HOME'], 'chef-repo')

output_dir = File.join(ENV['HOME'], cookbook_name, 'configure-a-package-and-service')

writers = Hash[%w(step1 step1_1 step2 step3 step4).map {
  |step|[step, OutputPath.new(File.join(output_dir, step))]
}]

directory output_dir do
  recursive true
end
writers.each_value do |writer|
  directory writer.base_path
end

directory working_dir do
  action [:create]
  recursive true
end

# 1. Install the Apache package
cookbook_file File.join(working_dir, 'webserver.rb') do
  source 'webserver_1.rb'
end

workflow_execute 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter' do
  cwd working_dir
  writer writers['step1']
end

workflow_execute 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter' do
  cwd working_dir
  writer writers['step1_1']
end

control_group 'lesson2, step1' do
  control 'validate output' do
    describe file(writers['step1'].stdout_path) do
      [
        /WARN: No config file/,
        /WARN: No cookbooks directory/,
        /Converging 1 resources/,
        /\* yum_package\[httpd\] action install/,
        /Chef Client finished, 1/
      ].each do |mater|
        its(:content) { should match matcher }
      end
    end
    describe file(writers['step1_1'].stdout_path) do
      its(:content) { should match /yum_package\[httpd\] action install \(up to date\)/ }
    end
  end
end

# 2. Start and enable the Apache service
cookbook_file File.join(working_dir, 'webserver.rb') do
  source 'webserver_2.rb'
end

workflow_execute 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter' do
  cwd working_dir
  writer writers['step2']
end

control_group 'lesson2, step2' do
  control 'validate output' do
    describe file(writers['step2'].stdout_path) do
      [
        /^\s{2}\* yum_package\[httpd\] action install \(up to date\)$/,
        /^\s{2}\* service\[httpd\] action enable$/,
        /^\s{4}\- enable service service\[httpd\]$/,
        /^\s{2}\* service\[httpd\] action start$/,
        /^\s{4}\- start service service\[httpd\]$/
      ].each do |matcher|
        its(:content) { should match matcher }
      end
    end
  end
end

# 3. Add a home page
cookbook_file File.join(working_dir, 'webserver.rb') do
  source 'webserver_3.rb'
end

workflow_execute 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter' do
  cwd working_dir
  writer writers['step3']
end

control_group 'lesson2, step3' do
  control 'validate output' do
    describe file(writers['step3'].stdout_path) do
      its(:content) { should match /^\s{4}\- create new file \/var\/www\/html\/index\.html$/ }
      its(:content) { should match /^\s{4}\- update content in file .+ from none/ }
      its(:content) { should match /^\s{4}\+\<html\>/ }
    end
  end
end

# 4. Confirm your web site is running
control_group 'lesson2, step4' do
  control 'validate output' do
    describe command('curl localhost') do
      its(:stdout) { should match <<-EOF.chomp
<html>
  <body>
    <h1>hello world</h1>
  </body>
</html>
EOF
}
    end
  end
end
