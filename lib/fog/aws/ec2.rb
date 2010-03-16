require 'fog/aws/models/ec2/address'
require 'fog/aws/models/ec2/addresses'
require 'fog/aws/models/ec2/flavor'
require 'fog/aws/models/ec2/flavors'
require 'fog/aws/models/ec2/image'
require 'fog/aws/models/ec2/images'
require 'fog/aws/models/ec2/key_pair'
require 'fog/aws/models/ec2/key_pairs'
require 'fog/aws/models/ec2/security_group'
require 'fog/aws/models/ec2/security_groups'
require 'fog/aws/models/ec2/server'
require 'fog/aws/models/ec2/servers'
require 'fog/aws/models/ec2/snapshot'
require 'fog/aws/models/ec2/snapshots'
require 'fog/aws/models/ec2/volume'
require 'fog/aws/models/ec2/volumes'
require 'fog/aws/requests/ec2/allocate_address'
require 'fog/aws/requests/ec2/associate_address'
require 'fog/aws/requests/ec2/attach_volume'
require 'fog/aws/requests/ec2/authorize_security_group_ingress'
require 'fog/aws/requests/ec2/create_key_pair'
require 'fog/aws/requests/ec2/create_security_group'
require 'fog/aws/requests/ec2/create_snapshot'
require 'fog/aws/requests/ec2/create_volume'
require 'fog/aws/requests/ec2/delete_key_pair'
require 'fog/aws/requests/ec2/delete_security_group'
require 'fog/aws/requests/ec2/delete_snapshot'
require 'fog/aws/requests/ec2/delete_volume'
require 'fog/aws/requests/ec2/describe_addresses'
require 'fog/aws/requests/ec2/describe_availability_zones'
require 'fog/aws/requests/ec2/describe_images'
require 'fog/aws/requests/ec2/describe_instances'
require 'fog/aws/requests/ec2/describe_reserved_instances'
require 'fog/aws/requests/ec2/describe_key_pairs'
require 'fog/aws/requests/ec2/describe_regions'
require 'fog/aws/requests/ec2/describe_security_groups'
require 'fog/aws/requests/ec2/describe_snapshots'
require 'fog/aws/requests/ec2/describe_volumes'
require 'fog/aws/requests/ec2/detach_volume'
require 'fog/aws/requests/ec2/disassociate_address'
require 'fog/aws/requests/ec2/get_console_output'
require 'fog/aws/requests/ec2/reboot_instances'
require 'fog/aws/requests/ec2/release_address'
require 'fog/aws/requests/ec2/revoke_security_group_ingress'
require 'fog/aws/requests/ec2/run_instances'
require 'fog/aws/requests/ec2/terminate_instances'

module Fog
  module AWS
    module EC2

      def self.new(options={})
        if Fog.mocking?
          Fog::AWS::EC2::Mock.new(options)
        else
          Fog::AWS::EC2::Real.new(options)
        end
      end

      class Mock

        def reset_data
          @data = {
            :deleted_at => {},
            :addresses => {},
            :instances => {},
            :key_pairs => {},
            :security_groups => {},
            :snapshots => {},
            :volumes => {}
          }
        end

        def initialize(options={})
          reset_data
        end

      end

      class Real

        # Initialize connection to EC2
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and 
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   sdb = SimpleDB.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use, in ['eu-west-1', 'us-east-1', 'us-west-1']
        #
        # ==== Returns
        # * EC2 object with connection to aws.
        def initialize(options={})
          unless @aws_access_key_id = options[:aws_access_key_id]
            raise ArgumentError.new('aws_access_key_id is required to access ec2')
          end
          unless @aws_secret_access_key = options[:aws_secret_access_key]
            raise ArgumentError.new('aws_secret_access_key is required to access ec2')
          end
          @hmac       = HMAC::SHA256.new(@aws_secret_access_key)
          @host = options[:host] || case options[:region]
          when 'eu-west-1'
            'ec2.eu-west-1.amazonaws.com'
          when 'us-east-1'
            'ec2.us-east-1.amazonaws.com'
          when 'us-west-1'
            'ec2.us-west-1.amazonaws.com'
          else
            'ec2.amazonaws.com'
          end
          @port       = options[:port]      || 443
          @scheme     = options[:scheme]    || 'https'
        end

        private

        def request(params)
          @connection = Fog::Connection.new("#{@scheme}://#{@host}:#{@port}")

          idempotent = params.delete(:idempotent)
          parser = params.delete(:parser)

          params.merge!({
            'AWSAccessKeyId' => @aws_access_key_id,
            'SignatureMethod' => 'HmacSHA256',
            'SignatureVersion' => '2',
            'Timestamp' => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
            'Version' => '2009-11-30'
          })

          body = ''
          for key in params.keys.sort
            unless (value = params[key]).nil?
              body << "#{key}=#{CGI.escape(value.to_s).gsub(/\+/, '%20')}&"
            end
          end

          string_to_sign = "POST\n#{@host}\n/\n" << body.chop
          hmac = @hmac.update(string_to_sign)
          body << "Signature=#{CGI.escape(Base64.encode64(hmac.digest).chomp!).gsub(/\+/, '%20')}"

          response = @connection.request({
            :body       => body,
            :expects    => 200,
            :headers    => { 'Content-Type' => 'application/x-www-form-urlencoded' },
            :idempotent => idempotent,
            :host       => @host,
            :method     => 'POST',
            :parser     => parser
          })

          response
        end

      end
    end
  end
end
