class Bitmap
  class << self
    def from_source(source)
      new(DimensionedBitmapData.new(source))
    end

    def with_dimensions(width, height, source)
      new(BitmapData.new(width, height, source))
    end

    private :new
  end

  def initialize(data)
    @data = data
  end

  def to_bytes
    @data.chunks.flat_map do |height, width, bytes|
      CHUNK_HEADER + [height, width] + bytes
    end
  end

  def width
    @data.width
  end

  CHUNK_HEADER = [18, 42]
  private_constant :CHUNK_HEADER
end

class BitmapData
  attr_reader :width

  def initialize(width, height, source)
    @source = ensure_is_queryable_for_bytes(source)
    @width = width
    @height = height
  end

  def chunks
    to_enum(:each_chunk)
  end

  private

  def ensure_is_queryable_for_bytes(source)
    return source if source.respond_to?(:getbyte)
    StringIO.new(source.map(&:chr).join)
  end

  def each_chunk
    chunk_heights.each do |chunk_height|
      yield chunk_height, width_in_bytes, get_bytes(width_in_bytes * chunk_height)
    end
  end

  def chunk_heights
    (1..number_of_chunks - 1).map { MAXIMUM_CHUNK_HEIGHT } << height_of_last_chunk
  end

  def width_in_bytes
    @width / 8
  end

  def get_bytes(amount)
    (1..amount).map { @source.getbyte }
  end

  def number_of_chunks
    Integer(@height / MAXIMUM_CHUNK_HEIGHT) + 1
  end

  def height_of_last_chunk
    @height % MAXIMUM_CHUNK_HEIGHT
  end

  MAXIMUM_CHUNK_HEIGHT = 255
  private_constant :MAXIMUM_CHUNK_HEIGHT
end

class DimensionedBitmapData < BitmapData
  def initialize(source)
    source = ensure_is_queryable_for_bytes(source)
    width = read_two_bytes(source)
    height = read_two_bytes(source)

    super(width, height, source)
  end

  private

  def read_two_bytes(source)
    first_byte = source.getbyte
    (source.getbyte << 8) + first_byte
  end
end
