module Rack::PerftoolsProfiler

  class ProfileOnce < ProfileDataAction
    include Rack::Utils
    include Rack::PerftoolsProfiler::Utils

    def self.has_special_param?(request)
      request.GET['profile'] != nil
    end

    def initialize(*args)
      super
      request = Rack::Request.new(@env)
      @times = (request.GET.fetch('times') {1}).to_i
      @mode = let(request.GET['mode']) do |m|
        if m.nil? || m.empty?
          nil
        else
          m.to_sym
        end
      end
      check_printer_arg
      @new_env = delete_custom_params(@env)
    end
    
    def act
      @profiler.profile(@mode) do
        @times.times { @middleware.call_app(@new_env) }
      end
    end

    def response
      @middleware.profiler_data_response(@profiler.data(@get_params))
    end

    def delete_custom_params(env)
      # I used to clone the env, but it broke any apps that used Warden
      # ex) new_env = env.clone
      new_env = env
      
      get_params = Rack::Request.new(new_env).GET
      get_params.delete('profile')
      get_params.delete('times')
      get_params.delete('printer')
      get_params.delete('ignore')
      get_params.delete('focus')

      new_env.delete('rack.request.query_string')
      new_env.delete('rack.request.query_hash')

      if get_params.values.map {|x| x.class}.include?(Hash)
        new_env['QUERY_STRING'] = build_nested_query(get_params)
      else
        new_env['QUERY_STRING'] = build_query(get_params)
      end
      new_env
    end

  end

end
