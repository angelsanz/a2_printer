class Bitmap
  attr_reader :width, :height

  class << self
    def from_source(source)
      data = obtain_data(source)
      width = read_width(data)
      height = read_height(data)

      Bitmap.with_dimensions(width, height, data)
    end

    def with_dimensions(width, height, source)
      new(width, height, obtain_data(source))
    end

    private

    def obtain_data(source)
      if source.respond_to?(:getbyte)
        source
      else
        StringIO.new(source.map(&:chr).join)
      end
    end

    def read_width(data)
      read_two_bytes(data)
    end

    def read_height(data)
      read_two_bytes(data)
    end

    def read_two_bytes(data)
      first_byte = data.getbyte
      (data.getbyte << 8) + first_byte
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
    each_block do |width, height, block|
      bytes = bytes + [18, 42, height, width] + block
    end

    bytes
  end


  private

  def each_block
    row_start = 0
    width_in_bytes = width / 8
    while row_start < height do
      chunk_height = ((height - row_start) > 255) ? 255 : (height - row_start)
      bytes = (0...(width_in_bytes * chunk_height)).map { @data.getbyte }
      yield width_in_bytes, chunk_height, bytes
      row_start += 255
    end
  end
end
