class Bitmap
  attr_reader :width, :height

  def initialize(width_or_source, height=nil, source=nil)
    if height.nil? && source.nil?
      set_source(width_or_source)
      extract_width_and_height_from_data
    else
      set_source(source)
      @width = width_or_source
      @height = height
    end
  end

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


  private

  def set_source(source)
    if source.respond_to?(:getbyte)
      @data = source
    else
      @data = StringIO.new(source.map(&:chr).join)
    end
  end

  def extract_width_and_height_from_data
    tmp = @data.getbyte
    @width = (@data.getbyte << 8) + tmp
    tmp = @data.getbyte
    @height = (@data.getbyte << 8) + tmp
  end
end