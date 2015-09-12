require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
        SQL
      result.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || "#{self}".tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
      SQL
      parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
        self.new(result)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{self.table_name}"
      WHERE
        id = ?
      SQL
      parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
        unless self.class.columns.include?(attr_name.to_sym)
            raise "unknown attribute '#{attr_name}'"
        end
        send("#{attr_name}=", value)
      end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert

    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
      SQL

      self.id = DBConnection.last_insert_row_id
  end

  def update
    set_names = self.class.columns.map do |column|
      "#{column} = ?"
    end.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_names}
      WHERE
        id = #{id}
      SQL
  end

  def save

    if id.nil?
      insert
    else
      update
    end

  end
end
