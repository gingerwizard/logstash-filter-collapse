# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require 'json'

# This collapse filter will take a list of paths.  Each of these paths will be navigated.  Every value for the path will be extracted and added to the target field if multi_valued is true,
# otherwise only the first value will be extracted.  The leafs must
# This filter handles both nested lists and maps - iterating as appropriate.
#
class LogStash::Filters::Collapse < LogStash::Filters::Base

  # Example:
  #
  # filter {
  #   collapse {
  #     map_fields => { "[field][sub_field][sub_sub_field]" => "copy_field" }
  #     multi_valued => true
  #   }
  # }
  #

  config_name "collapse"
  
  config :map_fields, :validate => :hash, :required =>true
  config :multi_valued, :validate => :boolean, :default => true


  public
  def register
  end

  public
  def filter(event)
    @map_fields.each do |src_fields, dest_field|
      fields = src_fields.split('][')
      values = read_field(event,fields)
      unless values.empty?
        event[dest_field]=values
      end
    end
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end

  def read_field(item,fields)
    values=[]
    fields.each do |field|
      field=field.gsub('[','').gsub(']','')
      sub_item = item[field]
      if !sub_item.nil?
        if sub_item.is_a?(Array) && fields.length > 1
          sub_item.each do |val|
            values=values+read_field(val,fields[1..-1])
          end
        elsif sub_item.is_a?(Hash)
            values=values+read_field(sub_item,fields[1..-1])
        elsif sub_item.is_a?(Array)
          #We will add arrays of primitives only
          sub_item.each do |val|
            if !(val.is_a?(Hash)) && !(val.is_a?(Array))
              values.push(val)
            end
          end
        else
          values.push(sub_item)
        end
      else
        return values
      end
    end
    return values
  end

end
