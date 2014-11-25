require "lita"

module Lita
  module Handlers
    class MustacheMe < Handler
      IMG_URL = "https://ajax.googleapis.com/ajax/services/search/images"
      URL = "http://mustachify.me/?src="
      VALID_SAFE_VALUES = %w(active moderate off)

      config :safe_search, types: [String, Symbol], default: :active do
        validate do |value|
          unless VALID_SAFE_VALUES.include?(value.to_s.strip)
            "valid values are :active, :moderate, or :off"
          end
        end
      end

      route(/^mustache(?:\s+me)? (.+)/, :fetch, command: true, help: {
	"mustache QUERY" => "Add a mustache to an image returned from Google Image search."
      })

      def fetch(response)
 	query = response.matches[0][0]

        http_response = http.get(
          IMG_URL,
          v: "1.0",
          q: query,
          safe: config.safe_search,
          rsz: 8
        )

        data = MultiJson.load(http_response.body)

        if data["responseStatus"] == 200
          choice = data["responseData"]["results"].sample
          if choice
            response.reply URL + ensure_extension(choice["unescapedUrl"])
          else
            response.reply %{No images found for "#{query}".}
          end
        else
          reason = data["responseDetails"] || "unknown error"
          Lita.logger.warn(
            "Couldn't get image from Google: #{reason}"
          )
        end
      end

      def ensure_extension(url)
        if [".gif", ".jpg", ".jpeg", ".png"].any? { |ext| url.end_with?(ext) }
          url
        else
          "#{url}#.png"
        end
      end
    end

    Lita.register_handler(MustacheMe)
  end
end
