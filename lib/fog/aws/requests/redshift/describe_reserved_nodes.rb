module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_reserved_nodes'

        # ==== Parameters
        # 
        # @param [Hash] options
        # * :reserved_node_id - (String) 
        #    The unique identifier for the node reservation.
        # * :max_records - (Integer) 
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the 
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String) 
        #    The marker returned from a previous request. If this parameter is specified, the 
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeReservedNodes.html             
        def describe_reserved_nodes(options = {})
          reserved_node_id = options[:reserved_node_id]
          marker           = options[:marker]
          max_records      = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeReservedNodes.new
          }

          params[:query]['Action']         = 'DescribeReservedNodes'
          params[:query]['ReservedNodeId'] = reserved_node_id if reserved_node_id
          params[:query]['Marker']         = marker if marker
          params[:query]['MaxRecords']     = max_records if max_records

          request(params)
        end
      end

    end
  end
end