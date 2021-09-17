control 'restic' do
  title 'should be installed & configured'

  describe package('restic') do
    it { should be_installed }
  end

  describe file('/etc/ssh/ssh_known_hosts') do
    its('content') { should match /^github.com ssh-rsa AAAA/ }
  end

  describe file('/root/.ssh/id_ed25519') do
    its('content') { should match /-----BEGIN OPENSSH PRIVATE KEY-----/ }
  end

  describe file('/root/.ssh/id_ed25519.pub') do
    its('content') { should match /ssh-ed25519/ }
  end

  describe file('/lib/systemd/system/restic.service') do
    its('content') { should match /PASSWORD='your-super-secret-passphrase'/ }
    its('content') { should match /AWS_ACCESS_KEY_ID='your-access-key-id'/ }
    its('content') { should match /AWS_SECRET_ACCESS_KEY='your-secret-access-key'/ }
    its('content') { should match /ftp:\/\/user:pass@your-server.com\/mybackup/ }
    its('content') { should match /--keep-monthly 6/ }
    its('content') { should match /--keep-weekly 1/ }
    its('content') { should match /pg_dumpall/ }
    its('content') { should match /'\/root'/ }
    its('content') { should match /'\/etc'/ }
    its('content') { should match /forget/ }
    its('content') { should match /Nice=10/ }
    its('content') { should match /IOSchedulingClass=2/ }
    its('content') { should match /IOSchedulingPriority=7/ }
  end

  describe file('/lib/systemd/system/restic.timer') do
    its('content') { should match /OnCalendar=02:00/ }
  end

  describe service('restic.timer') do
    it { should be_enabled }
    it { should be_running }
  end

  describe service('restic.service') do
    it { should_not be_running }
  end
end
