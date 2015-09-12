class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end

    names.each do |name|
      define_method("#{name}=") do |new_name|
        instance_variable_set("@#{name}", new_name)
      end
    end
  end
end

def name
  @name
end

def name=(new_name)
  @name = new_name
end
