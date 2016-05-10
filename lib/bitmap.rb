class Bitmap
  attr_reader :width

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
    each_chunk do |height, width, chunk|
      bytes += CHUNK_HEADER + [height, width] + chunk
    end

    bytes
  end


  private

  def each_chunk
    number_of_chunks.times do |chunk_number|
      height_offset = chunk_number * MAXIMUM_CHUNK_HEIGHT
      chunk_height = [@height - height_offset, MAXIMUM_CHUNK_HEIGHT].min

      yield chunk_height, width_in_bytes, @data.get_bytes(width_in_bytes * chunk_height)
    end
  end

  def number_of_chunks
    (@height / MAXIMUM_CHUNK_HEIGHT) + 1
  end

  def width_in_bytes
    width / 8
  end

  CHUNK_HEADER = [18, 42]
  MAXIMUM_CHUNK_HEIGHT = 255
  private_constant :MAXIMUM_CHUNK_HEIGHT, :CHUNK_HEADER
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

