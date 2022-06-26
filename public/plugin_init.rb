include ActionView::Helpers::NumberHelper

Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  ResultInfo.module_eval do
    # digital object processing
    def process_digital(json)
      dig_obj = {}
      dig_obj['material'] = json['digital_object_type'].blank? ? '' : json['digital_object_type']
      dig_obj['files'] = []
      unless json['digital_object_id'].blank? || !json['digital_object_id'].start_with?('http')
        dig_obj['out'] = json['digital_object_id']
      end
      dig_obj['files'] = process_file_versions(json)
      dig_obj['specific'] = process_specific(dig_obj)
      [dig_obj]
    end

    # representative digital object for an archival object
    def process_digital_instance(instances)
      dig_objs = []
      if instances && instances.is_a?(Array)
        instances.each do |instance|
          unless !instance.dig('digital_object', '_resolved')
            dig_f = {}
            it = instance['digital_object']['_resolved']
            if it.dig('publish') == true && !it['file_versions'].blank?
              dig_f['material'] = it['digital_object_type'].blank? ? '' : it['digital_object_type']
              dig_f['files'] = process_file_versions(it)
              dig_f['specific'] = process_specific(dig_f)
              unless dig_f['files'].empty?
                dig_objs.push(dig_f)
              end
            end
          end
        end
      end
      dig_objs
    end

    def process_specific(obj)
      specific = {}
      if obj['material'] == 'ebook'
        specific['online_readable_file'] = obj['files'].find {|item| item['file_format'] == 'epub'}
      end
      specific
    end

    # get links (including thumbnail, caption) for all digital objects
    def process_file_versions(json)
      dig_list = []
      unless json['file_versions'].blank?
        json['file_versions'].each do |version|
          embed_caption = ''
          rep_caption = ''
          dig_f = {}
          version['file_uri'].strip!
          if version.dig('publish') != false && version['file_uri'].start_with?('http')
            if version.has_key?('file_size_bytes')
              dig_f['file_size_bytes'] = version['file_size_bytes']
              dig_f['file_size_readable'] = number_to_human_size(version['file_size_bytes'], precision: 2)
            end
            if version.has_key?('file_format_name')
              dig_f['file_format'] = version['file_format_name']
            end
            if version['is_representative']
              dig_f['representative'] = true
            else
              dig_f['representative'] = false
            end
            dig_f['xlink_show'] = version.dig('xlink_show_attribute')
            dig_f['uri'] = version['file_uri']
            
            if version.dig('xlink_show_attribute') == 'embed'
              # For an embedded file version, if the caption is empty,
              # 1. set the embed_caption to the title
              # 2. set the rep_caption to the title if it is a representative version
              if version['caption'].blank?
                embed_caption = version['title']
                rep_caption = version['title'] if version['is_representative']
              else
                # For an embedded file version, if the caption is not empty,
                # 1. set the embed_caption to the caption
                # 2. set the rep_caption to the caption if it is a representative version
                embed_caption = version['caption']
                rep_caption = version['caption'] if version['is_representative']
              end
            else
              # if the caption is empty set the rep_caption to the title
              if version['caption'].blank?
                rep_caption = version['title']
              else
                # if the caption is not empty set the rep_caption to the caption
                rep_caption = version['caption']
              end
            end
            # Use the representative caption for the caption in the PUI if there is a
            # representative caption
            if !rep_caption.blank?
              dig_f['caption'] = rep_caption
            elsif !embed_caption.blank?
              # Use the embed caption for the caption in the PUI if there is isn't a
              # representative caption but there is an embedded caption
              dig_f['caption'] = rep_caption
            end
            caption = json.fetch(json['display_string'], json['title'])
            caption = '' if caption.blank?
            dig_f['caption'] = CGI::escapeHTML(strip_mixed_content(caption)) if dig_f['caption'].blank? && !dig_f['thumb'].blank?
            dig_list.append(dig_f)
          elsif !version['file_uri'].start_with?('http')
            Rails.logger.debug("****BAD URI? #{version['file_uri']}")
          end
        end
      end
      dig_list
    end
  end
end