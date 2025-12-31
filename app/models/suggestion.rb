class Suggestion < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  scope :popular, -> { order(frequency: :desc).limit(10) }

  def self.record_search(term)
    return if term.blank?

    suggestion = find_or_initialize_by(name: term.downcase)
    suggestion.frequency = (suggestion.frequency || 0) + 1
    suggestion.save
  end

  def as_json(options = nil)
    {
      name: name,
      frequency: frequency
    }
  end
end
