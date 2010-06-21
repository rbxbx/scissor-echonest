require 'scissor'
require 'echonest'
require 'scissor/echonest/chunk_ext.rb'

module Scissor
  def self.echonest_api_key=(echonest_api_key)
    Scissor::Chunk.echonest_api_key = echonest_api_key
  end

  class Chunk
    class << self
      attr_accessor :echonest_api_key
    end

    def self.echonest
      @echonest ||= Echonest(echonest_api_key)
    end

    def beats
      scissor_to_file

      if get_beats.any?
        append_beats_to([first_chunk])
      else
        append_beats_to([])
      end
    end

    def segments
      scissor_to_file
      get_segments.map do |segment|
        chunk = self[segment.start, segment.duration]
        chunk.set_delegate(segment)
        chunk
      end
    end

    private

    def beat
      @beat ||= Beat.new(get_beats.first.start, 1.0)
    end

    def first_chunk
      chunk = self[0, get_beats.first.start]
      chunk.set_delegate(beat)
    end

    def append_beats_to(chunks)
      get_beats.inject do |m, beat|
        chunk = self[m.start, beat.start - m.start]
        chunk.set_delegate(m)
        chunks << chunk
        beat
      end
    end

    def scissor_to_file
      to_file(tempfile_for_echonest, :bitrate => '64k')
    end

    def get_beats
      @get_beats ||= Chunk.echonest.get_beats(tempfile_for_echonest)
    end

    def get_segments
      @get_segments ||= Chunk.echonest.get_segments(tempfile_for_echonest)
    end

    def tempfile_for_echonest
      tmpfile = Pathname.new('/tmp/scissor_echonest_temp_' + $$.to_s + '.mp3')
      yield tmpfile
    ensure
      tmpfile.unlink
    end
  end
end
