Sequel.migration do

  up do
    types = [
        "ebook"
    ]
    enum = self[:enumeration].filter(:name => 'digital_object_digital_object_type').select(:id).first
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
