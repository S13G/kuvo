# frozen_string_literal: true

class SuggestionsController < ApplicationController
  def index
    query = params[:query].to_s.downcase

    @suggestions = nil
    if query.present?
      @suggestions = Suggestion.where("name ILIKE ?", "#{query}%")
                               .order(frequency: :desc)
                               .limit(10)
                               .pluck(:name)
    else
      @suggestions = Suggestion.popular.pluck(:name)
    end

    render_success(data: @suggestions.as_json)
  end
end
