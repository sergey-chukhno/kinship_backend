class Account::BadgesController < ApplicationController
  include ActiveStorage::SetCurrent
  before_action :set_token
  before_action :set_profile

  skip_before_action :authenticate_user!, only: [:tree, :level]

  def tree
    @user_badges = @user.badges_received
    @user_badges_count = @user_badges.count
    # Expected output: an array of UserBadge records

    @badges_categories = Badge.select(:name).distinct.pluck(:name)
    # Expected output : ["Collaboration", "Test 3", "Badge test niveau 1"]

    @user_badges_count_per_category = @user_badges.joins(:badge)
      .select("badges.name")
      .group("badges.name")
      .count
      .sort_by { |_, count| -count }
      .to_h
    # Expected output : {"Badge test niveau 1"=>1, "Collaboration"=>1}

    @percentage_per_category = @badges_categories.each_with_object({}) do |category, result|
      result[category] = if @user_badges_count_per_category[category].present?
        ((@user_badges_count_per_category[category].to_f / @user_badges_count) * 100).ceil
      else
        0
      end
    end.sort_by { |_, percentage| -percentage }.to_h
    # Expected output : {"Collaboration"=>50, "Badge test niveau 1"=>50, "Test 3"=>0}

    @user_badges_per_level = @user_badges.joins(:badge)
      .group("badges.name, badges.level")
      .select("badges.name, badges.level::text, COUNT(*) as count")
      .order("count DESC")
      .map { |result| [[result.name, "level_#{result.level.to_i + 1}"], result.count] }
      .to_h
    # Expected output : {["Badge test niveau 1", "level_1"]=>1, ["Collaboration", "level_2"]=>1}
  end

  def level
    # level = params[:level]
    category = params[:category]
    @user_badges = @user.badges_received.joins(:badge).where(badges: {name: category})
  end

  def download
    @user_badges = @user.badges_received
    @badges_categories = @user_badges.map { |badge| badge.badge.name }.uniq

    @parsed_badges = @badges_categories.map do |category|
      {
        category: category,
        badges: @user_badges.includes(:badge).where(badges: {name: category}).order(level: :desc).map do |badge|
          {
            description: badge.badge.description,
            project_title: badge.project.title,
            project_description: badge.project.description,
            domains: badge.badge_skills.domain.pluck(:name),
            expertises: badge.badge_skills.expertise.pluck(:name),
            level: badge.badge.level,
            comments: badge.comment,
            documents: badge.documents.map { |document|
              {
                url: document.url,
                name: document.filename.to_s
              }
            }
          }
        end
      }
    end

    respond_to do |format|
      format.pdf do
        render pdf: "Badge"
      end
    end
  end

  private

  def set_token
    if current_user && current_user.badges_token.nil?
      # Generate a random token if the user doesn't have one
      current_user.update(badges_token: SecureRandom.hex)
    end
  end

  def set_profile
    @user = User.find(params[:profile_id])
    authorize @user, policy_class: Account::BadgesPolicy
  end

  def pundit_user
    {user: current_user, token: params[:token]}
  end
end
