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
    width_in_bytes = width / 8
    number_of_blocks = (height / 255) + 1

    number_of_blocks.times do |block_number|
      block_height_offset = block_number * 255
      chunk_height = [height - block_height_offset, 255].min
      yield chunk_height, width_in_bytes, @data.get_bytes(width_in_bytes * chunk_height)
    end
  end
end

class BitmapData
  def initialize(source)
    @source = ensure_is_queryable_for_bytes(source)
  end

  def get_bytes(amount)
    (1..amount).map { @source.getbyte }
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

