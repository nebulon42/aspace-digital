Sequel.migration do

  up do
    types = [
        "epub",
        "epub3",
        "azw3"
    ]
    enum = self[:enumeration].filter(:name => 'file_version_file_format_name').select(:id).first
    types.each do |type|
      unless self[:enumeration_value].filter(:enumeration_id => enum[:id], :value => type).count > 0
        counter = self[:enumeration_value].filter(:enumeration_id => enum[:id]).order(:position).select(:position).last[:position]
        self[:enumeration_value].insert(:enumeration_id => enum[:id], :value => type, :readonly => 0, :position => counter + 1)
      end
    end

  end


  down do
  end

end
