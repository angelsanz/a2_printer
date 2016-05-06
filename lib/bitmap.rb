class Bitmap
  attr_reader :width, :height

  class << self
    def from_source(source)
      data = DimensionedBitmapData.new(source)
      new(data.width, data.height, data)
    end

    def with_dimensions(width, height, source)
      new(width, height, BitmapData.new(source))
    end

    private :new
  end

  def initialize(width, height, data)
      @data = data
      @width = width
      @height = height
  end

  def to_bytes
    bytes = []
    each_block do |height, width, block|
      bytes += [18, 42, height, width] + block
    end

    bytes
  end


  private

  def each_block
    row_start = 0
    width_in_bytes = width / 8
    while row_start < height do
      chunk_height = [height - row_start, 255].min
      yield chunk_height, width_in_bytes, @data.get_bytes(width_in_bytes * chunk_height)
      row_start += 255
    end
  end
end

class BitmapData
  def initialize(source)
    @source = ensure_is_queryable_for_bytes(source)
  end

  def get_bytes(amount)
    (0...amount).map { @source.getbyte }
  end

  private

  def ensure_is_queryable_for_bytes(source)
    return source if source.respond_to?(:getbyte)
    StringIO.new(source.map(&:chr).join)
  end
end

class DimensionedBitmapData < BitmapData
  attr_reader :width, :height

  def initialize(source)
    super(source)
    @width = read_two_bytes
    @height = read_two_bytes
  end

  private

  def read_two_bytes
    first_byte = @source.getbyte
    (@source.getbyte << 8) + first_byte
  end
end

