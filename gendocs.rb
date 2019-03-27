#!/usr/bin/env ruby

groups = [
  ["Managing windows",         :Window, :App, :Screen, :GridWM],
  ["Using OS features",        :Hotkey, :Pasteboard, :Notification],
  ["Various I/O",              :Files, :Net, :Shell],
  ["Accessing hardware",       :USB, :Wifi, :Keyboard, :Mouse, :Power, :Brightness],
  ["JavaScript runtime",       :localStorage, :console, :"(global)"],
  ["Helpers for using Autumn", :Autumn],
  ["Stringly typed constants", :KeyString, :ModString],
  ["Geometric classes",        :Rect, :Point, :Size, :RectLike, :PointLike, :SizeLike],
]

# the "t" method prefix ostensibly stands for "transform"

def tcommentblock s
  s
    .split("\n")
    .map{|s|s.sub(/\s\*\s?/, '')}
    .slice_after('')
    .to_a
    .map{|a|a.join("\n")}
end

def tmod((name, *docs))
  name = name[7..-1]
  (name, optsstr) = name.split(' ', 2)
  opts = {}
  optsstr.split(',').each do |opt|
    (key, val) = opt.split('=')
    opts[key.to_sym] = val
  end if optsstr
  {name: name, docs: docs}
end

def tmethod((name, *docs))
  {name: name, docs: docs}
end

def tsubgroup sg
  g = sg.shift
  g[:name].sub! 'group ', ''
  g[:methods] = sg
  g
end

def tgroup((mod, *methods))
  m = tmod(mod)
  methods.unshift(['group ']) unless methods[0][0].start_with? 'group '
  m[:groups] = methods
                 .map{|m|tmethod(m)}
                 .slice_before{|m| m[:name].start_with? 'group ' }
                 .map{|sg|tsubgroup sg}
  m
end

mods = Dir.glob('Autumn/Modules/*.m')
         .flat_map{ |file| File.read(file).lines }
         .join('')
         .gsub(/(?<=\/\*\*[\n ])(.+?)(?=\n? \*\/)/m)
         .map{|s|tcommentblock s}
         .slice_before{ |(line, *desc)| line.start_with? 'module ' }
         .map { |group| tgroup group }

# require 'pp'
# pp mods
# exit 0

modtable = mods.reduce({}) { |h, mod| h[mod[:name].to_sym] = mod; h }

gmods = groups.map do |(name, *modnames)|
  {name: name, mods: modnames.map{ |n| modtable[n] }}
end

require 'json'
File.write('Autumn/Web/docs.json', gmods.to_json)

def tdocs thing
  docs = thing[:docs]
  return if docs.empty?
  docstrings = docs.map{|line|' * '+line}.join("\n")
  "/**\n#{docstrings}\n */"
end

File.open('Autumn/Web/types.ts', 'w') do |f|
  mods.each do |mod|
    f.puts tdocs(mod)
    modname = mod[:name]
    f.puts "declare #{modname.end_with?('Like') ? 'interface' : 'class'} #{modname} {"
    mod[:groups].each do |group|
      group[:methods].each do |method|
        f.puts tdocs(method)
        f.puts method[:name]
      end
    end
    f.puts "}"
  end
end
