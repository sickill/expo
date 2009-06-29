#!/usr/bin/ruby
require 'fileutils'

class Photo
  # attr_accessor :styles
  attr_reader :src_mtime
  attr_reader :src_path
  attr_reader :src_name
  
  def initialize(src_path, dest_dir)
    @src_path = File.expand_path(src_path)
    @src_name = File.basename(@src_path)
    @dest_dir = File.expand_path(dest_dir)
    @src_mtime = File.mtime(@src_path)
    @style_defs = { :square => "75x75", :small => "240x180", :full => "800x600" }
    @styles = @style_defs.map { |name, geo| Style.new(self, File.join(@dest_dir, name.to_s), geo) }
  end
  
  def needs_update?
    @styles_to_update = @styles.select { |s| s.needs_update? }
    @styles_to_update.size > 0
  end
  
  # useful for 'pretend' mode
  def styles_to_update
    needs_update? unless @styles_to_update
    @styles_to_update
  end
  
  def update!
    if needs_update?
      @styles_to_update.each { |style| style.update! }
      true
    else
      false
    end
  end
  
end

class Style
  def initialize(photo, dir, geometry)
    @photo = photo
    @dir = dir
    @geometry = geometry
  end
  
  def needs_update?
    @photo.src_mtime > File.mtime(@dir)
  rescue Errno::ENOENT
    true
  end
  
  def update!
    FileUtils.mkdir_p(@dir) unless File.directory?(@dir)
    dest_path = File.join(@dir, @photo.src_name.gsub(/\.[^\.]+$/, ".jpg"))
    cmd = "convert #{@photo.src_path} -thumbnail #{@geometry} #{dest_path}"
    puts "running: #{cmd}"
    `#{cmd}`
  end
end

p = Photo.new(ARGV[0], ARGV[1])
p.update!
