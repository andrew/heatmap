require 'ostruct'
module Heatmap
  class Density < Base
    # Colours each pixel based on the the number of nearby points, weighted by their distance to the pixel
    def render_pixel(lat, lng)
      value = 0
      alpha = 0
      any = false
      closest_dist = nil

      @points.each do |point|
        # Calculate the distance
        dist = distance(lat, lng, point.lat, point.lng)

        # Skip point if it is outside of the effect distance
        next if dist > @options[:effect_distance]

        closest_dist ||= dist
        closest_dist = dist if dist < closest_dist

        any = true

        value += point.value * (1 - dist / @options[:effect_distance])
      end

      return any ? value : TRANSPARENT_PIXEL
    end
  end
end
