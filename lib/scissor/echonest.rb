require 'scissor'
require 'echonest'

module Scissor
  def self.echonest_api_key=(echonest_api_key)
    Scissor::Chunk.echonest_api_key = echonest_api_key
  end

  class Chunk
    class << self
      attr_accessor :echonest_api_key
    end

    def echonest
      Echonest(self.class.echonest_api_key)
    end

    def beats
      tempfile_for_echonest do |tmpfile|
        chunks = []
        scissor = to_file(tmpfile)

        beats = echonest.get_beats(tmpfile)
        beats.inject do |m, beat|
          chunks << self[m.start, beat.start - m.start]
          beat
        end

        chunks
      end
    end

    def segments
      tempfile_for_echonest do |tmpfile|
        scissor = to_file(tmpfile)

        segments = echonest.get_segments(tmpfile)
        segments.inject([]) do |chunks, segment|
          chunks << self[segment.start, segment.duration]
          chunks
        end
      end
    end

    private

    def tempfile_for_echonest
      tmpfile = Pathname.new('/tmp/scissor_echonest_temp_' + $$.to_s + '.mp3')
      yield tmpfile
    ensure
      tmpfile.unlink
    end
  end
end
