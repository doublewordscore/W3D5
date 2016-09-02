require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    @col_titles ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @col_titles.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) { self.attributes[col] }

      define_method("#{col}=") { |val| self.attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= name.tableize
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
      #{table_name}
    SQL
    self.parse_all(rows)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    answer = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL
    return nil if answer.length == 0
    parse_all(answer).first
  end



  def initialize(params = {})
    params.each do |attr_name, val|
      if self.class.columns.include?(attr_name.to_sym)
        self.send("#{attr_name.to_sym}=", val)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}

  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    columns = self.class.columns
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * columns.length).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end


  def update
    columns = self.class.columns
    set_line = columns.map {|attr_name| "#{attr_name} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL

  end

  def save
    id.nil? ? insert : update
  end
end
