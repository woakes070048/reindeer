##
# Sort lime_surveys into groups based on their group name
# RoleAggregateGroup.classify(lime_surveys)
class LimeExt::LimeSurveyGroup
  attr_reader :lime_surveys, :group_title
  alias_method :title, :group_title
  alias_method :surveys, :lime_surveys


  def self.classify(lime_surveys, opts = {})
    # dup our own copy of array to mutate
    lime_surveys = lime_surveys.to_a.dup
    groups = GroupCollection.new
    while lime_surveys.present?
      groups.push(new(lime_surveys))
    end

    # Filter groups if filter present
    filter = *opts[:filter]
    if filter.present?
      groups.select!{|group| filter.include?(group.title) }
    end
    groups
  end

  def initialize lime_surveys
    @lime_surveys = []
    lime_surveys.delete_if{ |ls| @lime_surveys.push(ls) if in_group?(ls) }
  end

  def role_aggregates
    @role_aggregates ||= surveys.map{|survey| survey.role_aggregate }
  end

  protected

  ##
  # Is title a part of this group?
  def in_group?(lime_survey)
    g_title, ra_title = lime_survey.group_and_title_name


    #if g_title == nil
    #    g_title = n_title
    #end

    @group_title ||= g_title
    group_title == g_title
  end

  ##
  # Simple array class for holding a collection of
  # survey groups
  class GroupCollection < Array

    def initialize( items=nil, opts={} )
      @filter = *opts[:filter]
      items = *items
      items.each{|item| push(item) if in_filter?(item) }
    end

    def in_filter? item
      @filter.empty? || @filter.include?(item.title)
    end

    def filter filter
      self.class.new(self, filter: filter)
    end

    def titles
      map{|group|group.title}
    end

    def role_aggregates
      map{|group|group.role_aggregates}.flatten
    end

    def lime_surveys
      map{|group|group.lime_surveys}.flatten
    end
  end
end
