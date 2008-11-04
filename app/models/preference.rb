# Represents a preferred value for a particular preference on a model.
# 
# == Grouped preferences
# 
# In addition to simple named preferences, preferences can also be grouped by
# a particular value, be it a string or ActiveRecord object.  For example, a
# User may have a preferred color for a particular Car.  In this case, the
# +owner+ is the User, the +attribute+ is the color, and the +group+ is the Car.
# This allows preferences to have a sort of context around them.
class Preference < ActiveRecord::Base
  belongs_to  :owner,
                :polymorphic => true
  belongs_to  :group,
                :polymorphic => true
  
  validates_presence_of :attribute,
                        :owner_id,
                        :owner_type
  validates_presence_of :group_type,
                          :if => :group_id?
  
  class << self
    # Splits the given group into its corresponding id and type. For simple
    # primitives, the id will be nil.  For complex types, specifically ActiveRecord
    # objects, the id is the unique identifier stored in the databse for the
    # record.
    # 
    # For example,
    # 
    #   Preference.split_group('google')      # => [nil, "google"]
    #   Preference.split_group(1)             # => [nil, 1]
    #   Preference.split_group(User.find(1))  # => [1, "User"]
    def split_group(group = nil)
      if group.is_a?(ActiveRecord::Base)
        group_id, group_type = group.id, group.class.base_class.name.to_s
      else
        group_id, group_type = nil, group
      end
      
      [group_id, group_type]
    end
  end
  
  # The definition for the attribute
  def definition
    owner.class.preference_definitions[attribute] if owner_type
  end
  
  # Typecasts the value depending on the preference definition's declared type
  def value
    value = read_attribute(:value)
    value = definition.type_cast(value) if definition
    value
  end
  
  # Only searches for the group record if the group id is specified
  def group_with_optional_lookup
    group_id ? group_without_optional_lookup : group_type
  end
  alias_method_chain :group, :optional_lookup
end
