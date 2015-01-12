module Heatmap
  class Base
    UNPROCESSED_PIXEL = -1 # Fill the picture with these pixels which should be distinguishable from the transparent pixel so we can tell if the pixel has been processed
    TRANSPARENT_PIXEL = 0

    # OPTIONS:
    #  :bounds => [max_lat, max_lng, min_lat, min_lng]
    #  :height => height in px of the output image (width is determined by the bounding box aspect ratio)
    #  :effect_distance => distance in decimal degrees over which we ignore the influence of points

    attr_reader :pixels, :points

    def initialize(points, bounds, options = {})
      @options = {:effect_distance => 0.01}.merge options

      @min_lat, @min_lng, @max_lat, @max_lng = bounds

      # Determine the dimensions of the output image
      @output_height = @options[:height]
      @output_width  = @options[:width]

      @points = points

      # Build pixels in scanline order, left to right, top to bottom
      pixels = Array.new(@output_height) { Array.new(@output_width, UNPROCESSED_PIXEL) }

      effect_distance_in_px = ll_to_pixel(0, @options[:effect_distance])[0] - ll_to_pixel(0, 0)[0] + 1 # Round up so edges don't get clipped

      @points.each do |point|
        # Only render the pixels that are affected by a point
        x, y = ll_to_pixel(point.lat, point.lng)

        x_range = Range.new([x - effect_distance_in_px, 0].max, [x + effect_distance_in_px, @output_width].min, true)
        y_range = Range.new([y - effect_distance_in_px, 0].max, [y + effect_distance_in_px, @output_height].min, true)

        y_range.each do |y|
          x_range.each do |x|
            next unless pixels[y][x] == UNPROCESSED_PIXEL # Only render each pixel once, even though renderable areas overlap

            pixels[y][x] = render_pixel(*pixel_to_ll(x,y))
          end
        end
      end

      max = pixels.flatten.max

      @pixels = pixels.map do |row|
        row.map do |pixel|
          val = scale(pixel, max).round
          val = 0 if val == -1
          val
        end
      end
    end

    def scale(val, max)
      ((3 - 0) * (val - 0)) / (max - 0) + 0
    end

    private

    def optimize_points(points)
      # Select only the points that will have an effect on the output image
      points.select do |point|
        @min_lat - @options[:effect_distance] <= point.lat &&
        @max_lat + @options[:effect_distance] >= point.lat &&
        @min_lng - @options[:effect_distance] <= point.lng &&
        @max_lng + @options[:effect_distance] >= point.lng
      end
    end

    # NOTE: this calculation is not accurate for extreme latitudes
    def pixel_to_ll(x,y)
      delta_lat = @max_lat-@min_lat
      delta_lng = @max_lng-@min_lng

      # x is lng, y is lat
      # 0,0 is @min_lng, @max_lat

      x_frac = x.to_f / @output_width
      y_frac = y.to_f / @output_height

      lng = @min_lng + x_frac * delta_lng
      lat = @max_lat - y_frac * delta_lat


      calc_x, calc_y = ll_to_pixel(lat, lng)

      if (calc_x-x).abs > 1 || (calc_y-y).abs > 1
        puts "Mismatch: #{x}, #{y} => #{calc_x} #{calc_y}"
      end

      return lat, lng
    end

    # NOTE: this calculation is not accurate for extreme latitudes
    def ll_to_pixel(lat,lng)
      adj_lat = lat - @min_lat
      adj_lng = lng - @min_lng

      delta_lat = @max_lat - @min_lat
      delta_lng = @max_lng - @min_lng

      # x is lng, y is lat
      # 0,0 is @min_lng, @max_lat

      lng_frac = adj_lng / delta_lng
      lat_frac = adj_lat / delta_lat

      x = (lng_frac * @output_width).to_i
      y = ((1-lat_frac) * @output_height).to_i

      return x, y
    end

    # Distance between two points in 2D space
    def distance(x1,y1,x2,y2)
      Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))
    end

    def render_pixel
      raise NotImplementedError
    end

    def colour(val)
      return [val]
      floor = @options[:legend].detect{|key, value| val >= key }
      ceiling = @options[:legend].to_a.reverse.detect{|key, value| val < key }

      if ceiling && floor
        blend(ceiling[1], floor[1], (val - floor[0]).to_f / (ceiling[0] - floor[0]))
      elsif floor
        floor[1]
      elsif ceiling
        ceiling[1]
      end
    end

    # Bias is 0..1, how much of colour one to use
    def blend(colour1, colour2, bias)
      colour1 = colour1.collect{|channel| channel * bias}
      colour2 = colour2.collect{|channel| channel * (1 - bias)}
      blended = colour1.each_with_index.collect{|channel, index| (channel.to_f + colour2[index])}
      return blended
    end
  end
end
