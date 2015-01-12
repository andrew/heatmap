module Heatmap
  class Density < Base
    # Group duplicate points and set each point value based on the total number of points
    def optimize_points(points)
      points = super
      total = points.count
      points = points.group_by(&:id).collect {|_, points| OpenStruct.new(:value => points.count, :lat => points[0].lat, :lng => points[0].lng) }

      return points
    end

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

      colr = colour(value)
      colr[3] = [1, (1 - closest_dist.to_f / @options[:effect_distance])].min * 255 # Assign alpha value based on the distance to the closest point
      return any ? colr : TRANSPARENT_PIXEL
    end
  end
end
