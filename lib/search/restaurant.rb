#!/usr/bin/env ruby -wKU
# encoding: UTF-8

require 'csv'

module Search
  class Restaurant

    attr_accessor :restaurant_menus, :items, :search_results

    def	initialize(file)
      @file = file
      @restaurant_menus = {}
      @items = []
      parse_file
    end

    # instance methods to find the best price for the given item labels array
    def	my_best_deal(item_labels)
      @item_search, @meal_combo, @search_result = [], [], []
      if item_present?(item_labels)
        search_my_combo
        sort_menu_combo
        find_cheapest_deal
        show_best_possible_deal
      else
        "Menu item not found"
      end
    end

    def dup_hash(array)
      hash = Hash.new(0)
      array.each { | v | hash.store(v, hash[v]+1) }
      hash
    end

    private

    # Parses each row of the CSV file, and validates the data.
    def	parse_file
      # IO.foreach doesn't read the entire file into memory at once, which is good since a standard FasterCSV.parse on this file can take an hour or more
      rows = []
      IO.foreach(@file) do |row|
        rows << row
        if rows.size >= 1000
          rows = CSV.parse(rows.join) rescue next
          load rows
          rows = []
        end
      end
      load rows
    end

    # perform minimum validation checks on the restaurant_id, price and item being added to the list
    def validate(restaurant_id, price, item)
      restaurant_id > 0 && price > 0.0 && !item.nil? && !item.empty?
    end

    # add the restaurant_id, price and menu_item to the restaurant_list hash
    def	load(rows)
      rows.each do |row|
        restaurant_id, price, item = row[0].strip, row[1].strip, row[2..-1].map(&:strip).join('-').downcase
        if validate(restaurant_id, price, item)
          # @restaurant_menus[restaurant_id] = {} unless @restaurant_menus.has_key?(restaurant_id)
          @restaurant_menus[restaurant_id.to_s].merge(price.to_s => item)
        else
          puts("Escaping invalid row: #{row}")
        end
      end
    end


    def item_present?(item_labels)
      @restaurant_menus.each do |hash|
        return if (hash.values & item_labels).sort == item_labels.sort
      end
    end

    # meal_combo is the intersection of ('item_search') item_id that contains all the search items
    def search_my_combo
      search = @item_search.flatten
      hash = dup_hash(search)
      @meal_combo = hash.keys.select{|k| hash[k] == @item_search.length}
    end

    # removes the menu items one by one as searched from the searched item's array.
    def sort_menu_combo
      @item_search.collect! { |search| search = (search - @meal_combo)} unless @meal_combo.empty?
    end

    # find the cheapest deal for the selected menu item.
    def find_cheapest_deal
      @restaurant_menus.map do |restaurant, value|
        min_price = minimum_price_per_restaurant(restaurant)
        puts min_price
        min_price = minimum_price_combo_meal(restaurant)
        @search_result << [restaurant, min_price] if !@meal_combo.empty? && min_price > 0
      end
    end

    # returns the minimum price of the menu items searched for.
    def minimum_price_per_restaurant(restaurant)
      menu_item = {}
      @item_search.each_with_index do |search, index|
        menu_item[index] = []
        search.each do |item|
          menu_item[index] << @restaurant_menus[restaurant][item] if @restaurant_menus[restaurant].has_key? item
        end
        menu_item[index] = menu_item[index].sort.first unless menu_item[index].empty?
      end
      menu_item.values.reduce(:+)
    end

    # it calculates the minimum combo price at a given restaurant
    def minimum_price_combo_meal(restaurant)
      price = []
      @meal_combo.each do |cm|
        price << @restaurant_menus[restaurant][cm] if @restaurant_menus[restaurant].has_key? cm
      end
      price.empty? ? 0 : price.sort.first
    end

    # returns nil if @results are empty
    # returns the restaurant_id, min_price from the @search_result array of array
    def show_best_possible_deal
      return nil if @search_result.empty?
      restaurant_id = @search_result[0][0]
      min_price = @search_result[0][1]
      @search_result[1..-1].each do |restaurant, price|
        restaurant_id, min_price = restaurant, price if price < min_price
      end
      [restaurant_id, min_price]
    end
  end
end