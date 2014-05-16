module RodeoClown
  module InstanceBuilder
    attr_reader   :key_pair
    attr_accessor :tags
    attr_reader   :availability_zones
    attr_reader   :options

    def many_from_options(options)
      options = options.symbolize_keys # Create a duplicate

      @key_pair_name = options.delete(:key_pair_name)
      @tags          = options.delete(:tags)
      @options       = options
      @availability_zones = options.delete(:availability_zones) || []
    end

    def key_pair=(key_pair_name)
      @key_pair = AWS::EC2::KeyPair.new(key_pair_name)
    end

    def build_options
      if availability_zones.any?
        availability_zones.map do |zone|
          configs.merge(availability_zone: zone)
        end
      else
        [configs]
      end
    end

    def build_instances(num = false)
      if num
        build_options = self.build_options.first(num)
      end

      build_options.map do |options|
        instances = create_instance options
        apply_tags(instances)
        instances
      end.flatten
    end

    private

    def apply_tags(instances)
      rc_tags = { "rc_created_by" => "Rodeo Clown #{RodeoClown::VERSION}",
        "rc_created_at" => Time.now.to_s }

      [*instances].each {|i| i.tags.set(tags.merge(rc_tags)) }
    end

    def configs
      options.merge(:key_pair => key_pair)
    end
  end
end
