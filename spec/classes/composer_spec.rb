require 'spec_helper'

describe 'composer' do
  ['RedHat', 'Debian', 'Linux'].each do |osfamily|
    case osfamily
    when 'RedHat'
      php_package = 'php-cli'
      php_context = '/files/etc/php.ini/PHP'
      suhosin_context = '/files/etc/suhosin.ini/suhosin'
    when 'Linux'
      php_package = 'php-cli'
      php_context = '/files/etc/php.ini/PHP'
      suhosin_context = '/files/etc/suhosin.ini/suhosin'
    when 'Debian'
      php_package = 'php5-cli'
      php_context = '/files/etc/php5/cli/php.ini/PHP'
      suhosin_context = '/files/etc/php5/conf.d/suhosin.ini/suhosin'
    else
      php_package = 'php-cli'
      php_context = '/files/etc/php.ini/PHP'
      suhosin_context = '/files/etc/suhosin.ini/suhosin'
    end

    context "on #{osfamily} operating system family" do
      let(:facts) { {
          :osfamily        => osfamily,
          :operatingsystem => 'Amazon'
      } }

      it { should contain_class('composer::params') }

      it {
        should contain_exec('download_composer').with({
          :command     => 'curl -s https://getcomposer.org/installer | php',
          :cwd         => '/tmp',
          :creates     => '/tmp/composer.phar',
          :logoutput   => false,
        })
      }

      it {
        should contain_augeas('whitelist_phar').with({
          :context     => suhosin_context,
          :changes     => 'set suhosin.executor.include.whitelist phar',
        })
      }

      it {
        should contain_augeas('allow_url_fopen').with({
          :context    => php_context,
          :changes    => 'set allow_url_fopen On',
        })
      }

      context 'with default parameters' do
        it 'should compile' do
          compile
        end

        it { should contain_package(php_package).with_ensure('present') }
        it { should contain_package('curl').with_ensure('present') }
        it { should contain_file('/usr/local/bin').with_ensure('directory') }

        it {
          should contain_file('/usr/local/bin/composer').with({
            :source => 'present',
            :source => '/tmp/composer.phar',
            :mode   => '0755',
          })
        }

        it { should_not contain_exec('setup_github_token') }
      end

      context "on invalid operating system family" do
        let(:facts) { {
          :osfamily        => 'Invalid',
          :operatingsystem => 'Amazon'
        } }

        it 'should not compile' do
          expect { should compile }.to raise_error(/Unsupported platform: Invalid/)
        end
      end

      context 'with custom parameters' do
        let(:params) { {
          :target_dir      => '/you_sir/lowcal/been',
          :php_package     => 'php8-cli',
          :composer_file   => 'compozah',
          :curl_package    => 'kerl',
          :php_bin         => 'pehpe',
          :suhosin_enabled => false,
          :github_token    => 'my_token',
        } }

        it 'should compile' do
          compile
        end

        it { should contain_package('php8-cli').with_ensure('present') }
        it { should contain_package('kerl').with_ensure('present') }
        it { should contain_file('/you_sir/lowcal/been').with_ensure('directory') }

        it {
          should contain_file('/you_sir/lowcal/been/compozah').with({
            :source => 'present',
            :source => '/tmp/composer.phar',
            :mode   => '0755',
          })
        }

        it { should_not contain_augeas('whitelist_phar') }
        it { should_not contain_augeas('allow_url_fopen') }

        it {
          should contain_exec('setup_github_token').with({
            :command => "/you_sir/lowcal/been/compozah config -g github-oauth.github.com my_token",
            :cwd     => '/tmp',
            :unless  => "/you_sir/lowcal/been/compozah config -g github-oauth.github.com|grep my_token",
          })
        }
      end

      context 'when receiving a projects hash' do
        let(:params) { {
          :projects        => { 'library1' => { 'project_name' => 'lib1', 'target_dir' => '/home/lib1' }, 'library2' => { 'project_name' => 'lib2', 'target_dir' => '/home/lib2' } }
        } }

        it {
          should contain_composer__project('library1').with({
            'project_name' => 'lib1',
            'target_dir'   => '/home/lib1',
          })
        }

        it {
          should contain_composer__project('library2').with({
            'project_name' => 'lib2',
            'target_dir'   => '/home/lib2',
          })
        }

        it { should have_composer__project_resource_count(2) }

      end
    end
  end
end
