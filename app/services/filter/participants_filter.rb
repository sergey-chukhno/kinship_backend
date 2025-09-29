module Filter
  class ParticipantsFilter < ApplicationService
    def initialize(collection:, options: nil)
      @collection = collection
      @options = options&.each do |_key, value|
        if value.is_a?(Array)
          value.compact_blank!
        end
      end
    end

    def call
      return @collection.uniq unless @options

      @collection = filter_by_school unless @options[:school].blank?
      @collection = filter_by_school_level unless @options[:school_level].blank?
      @collection = filter_by_company unless @options[:company].blank?
      @collection = filter_by_project unless @options[:project].blank?
      @collection = filter_by_skills unless @options[:skills].blank?
      @collection = filter_by_sub_skills unless @options[:sub_skills].blank?
      @collection = filter_by_availabilities if @options[:availabilities].to_h.any? { |_, v| v == "1" }
      @collection = filter_by_take_trainee unless @options[:take_trainee].blank?
      @collection = filter_by_propose_workshop unless @options[:propose_workshop].blank?
      @collection.uniq
    end

    private

    def filter_by_attribute(attribute, value)
      return @collection if @collection.empty?
      if @collection.is_a?(ActiveRecord::Relation)
        @collection.where(attribute => value)
      else
        @collection.select do |item|
          item_value = item.send(attribute)
          returned_value = false

          if item_value.is_a?(TrueClass)
            returned_value = value.include?("true") || value.include?(true)
          end

          if returned_value == false && item_value.is_a?(FalseClass)
            returned_value = value.include?("false") || value.include?(false)
          end

          returned_value
        end
      end
    end

    def filter_by_school
      return @collection if @collection.empty?
      @collection.where(schools: {id: @options[:school]})
    end

    def filter_by_school_level
      return @collection if @collection.empty?
      @collection.joins(:user_school_levels).where(user_school_levels: {school_level_id: @options[:school_level]})
    end

    def filter_by_company
      return @collection if @collection.empty?
      @collection.where(companies: {id: @options[:company]})
    end

    def filter_by_project
      return @collection if @collection.empty?
      @collection.where(project_members: {project_id: @options[:project]})
    end

    def filter_by_skills
      return @collection if @collection.empty?
      @collection.where(skills: @options[:skills])
    end

    def filter_by_sub_skills
      return @collection if @collection.empty?
      @collection.joins(:user_sub_skills).where(user_sub_skills: {sub_skill_id: @options[:sub_skills]})
    end

    def filter_by_availabilities
      return @collection if @collection.empty?
      filter = @options[:availabilities].to_h.select { |_, v| v == "1" }
      @collection.where(availability: filter)
    end

    def filter_by_take_trainee
      filter_by_attribute(:take_trainee, @options[:take_trainee])
    end

    def filter_by_propose_workshop
      filter_by_attribute(:propose_workshop, @options[:propose_workshop])
    end
  end
end
