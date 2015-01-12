module Heatmap
  class WeightedAverage < Base
    def optimize_points(points)
      points = super
      @quadtree = Kdtree.new(points.each_with_index.collect{|p, index| [p.lat, p.lng, index]})
      return points
    end

    # Inverted distance weighted average
    # Colours each pixel based on the average value of the surrounding points, weighted by their distance to the pixel
    def render_pixel(lat, lng)
      num = 0
      dnm = 0
      any = false

      # OPTIMIZATION: get the closest 5 points
      @quadtree.nearestk(lat, lng, 5).each do |point_index|
        point = @points[point_index]

        # Calculate the distance
        dist = distance(lat, lng, point.lat, point.lng)

        # Skip point if it is outside of the effect distance
        next if dist > @options[:effect_distance]

        any = true
        inv_dist = dist == 0 ? 1 : 1 / dist

        num += point.value * inv_dist
        dnm += inv_dist
      end

      if !any
        return TRANSPARENT_PIXEL
      elsif dnm == 0
        return colour(num)
      else
        return colour(num / dnm)
      end
    end
  end
end
