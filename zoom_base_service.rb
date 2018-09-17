module Zoom
  class BaseService
    def initialize(session = {})
      @session = session
      @authenticate_iteration = 0
    end

    def request(method, path, params = nil)
      body = params ? params.to_json : nil
      url = URI(path)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTPGenericRequest.new(
                  method,
                  body.present?,
                  response_has_body = true,
                  url.request_uri,
                  {}
                )

      request_headers(request)
      result = response(http, request, body)
      result[:authorized?] || result[:code] == 508 ? result : authenticate(method, path, params, result)
    end

    def request_headers(request)
      request['Authorization'] = "Bearer #{@session['zoom_token']}"
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'
    end

    def authenticate(method, path, params, result)
      loop do
        @session['zoom_token'] = TokenGenerator.new.get_JWT_token

        break if result[:authorized?]

        if @authenticate_iteration == 3
          result[:code] = 508
          result[:message] = 'Loop detected in authentication'
          break
        end

        @authenticate_iteration += 1
        result = request(method, path, params)
      end

      result
    end

    def response(http, request, body)
      reply = http.request(request, body)
      code = reply.code.to_i

      {
        collection: (reply.body.nil? || !successful_status?(code))  ? '' : JSON.parse(reply.body),
        successful?: successful_status?(code),
        code: code,
        authorized?: authorized_request?(code),
        message: "#{reply.message}. #{JSON.parse(reply.body)['message'] if reply.body}"
      }.with_indifferent_access
    end

    def successful_status?(status)
      status >= 200 && status <= 299
    end

    def authorized_request?(status)
      status != 401
    end
  end
end
