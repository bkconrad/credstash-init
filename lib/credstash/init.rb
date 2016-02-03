require "erb"
require "json"
require "credstash/init/version"
require "aws-sdk-resources"

module Credstash
  class Init
    # Your code goes here...
    def init!
      usage! unless profile_name && region && users.any?
      %w(production staging development global).each do |env|
        ensure_kms_key_exists env
        run_credstash_setup env
        next if env == 'global'
        ensure_kms_key_exists "#{env}-releases"
        run_credstash_setup "#{env}-releases"
      end
    end

    def usage!
      puts "Usage: #{$0} <profile> <region> <admin_username> [ ... ]"
      puts "You must provide a profile, region, and list of users (in that order)"
      exit 1
    end

    private

    def ensure_kms_key_exists env
      create_kms_key! env unless kms_key_exists? env
    end

    def kms_key_exists? env
      begin
        kms.describe_key(key_id: key_name(env))
        puts "Found existing key alias #{key_name env}"
        return true
      rescue Aws::KMS::Errors::NotFoundException => e
        return false
      end
    end

    def create_kms_key! env
      puts "Creating KMS Key for #{env}"
      result = kms.create_key description: "Credstash key for #{env} secrets", policy: policy(env)
      puts "Creating KMS Alias #{key_name env}"
      kms.create_alias alias_name: key_name(env), target_key_id: result.key_metadata.key_id
    end

    def policy env
      template_file = File.join File.dirname(__FILE__), 'template', 'credstash-key-policy.json.erb'

      # expose some variables to the binding
      @env = env
      @account_id = account_id
      data = JSON.parse ERB.new(File.read(template_file)).result(binding)
      require 'pp'
      data['Statement'].each do |statement|
        next unless statement['Principal']['AWS'].is_a? Array
        statement['Principal']['AWS'] = user_arns
      end

      JSON.pretty_generate data
    end

    def user_arns
      users.map { |user| "arn:aws:iam::#{account_id}:user/#{user}" }
    end

    def account_id
      iam.get_user.user.arn.split(':')[4]
    end

    def key_name env
      "alias/credstash-#{env}"
    end

    def run_credstash_setup env
      system "credstash -p #{profile_name} -r #{region} -t credstash-#{env} setup"
    end

    def kms
      @kms ||= ::Aws::KMS::Client.new profile: profile_name, region: region
    end

    def iam
      @iam ||= ::Aws::IAM::Client.new profile: profile_name, region: region
    end

    def profile_name
      ARGV.first
    end

    def region
      ARGV[1]
    end

    def users
      ARGV.last ARGV.length - 2
    end
  end
end
