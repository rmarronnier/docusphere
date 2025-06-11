# Helper to correct common test data issues
module TestDataCorrections
  COLUMN_MAPPINGS = {
    submitted_at: :submitted_date,
    approved_at: :approved_date,
    approval_date: :approved_date,
    submission_deadline: :expected_approval_date,
    planned_start_date: :start_date
  }.freeze

  PERMIT_TYPE_MAPPINGS = {
    'building' => 'construction',
    'signage' => 'declaration',
    'pre_demolition' => 'demolition'
  }.freeze

  def correct_permit_attributes(attrs)
    corrected = attrs.dup
    
    # Correct column names
    COLUMN_MAPPINGS.each do |old_name, new_name|
      if corrected.key?(old_name)
        corrected[new_name] = corrected.delete(old_name)
      end
    end
    
    # Correct permit types
    if corrected[:permit_type] && PERMIT_TYPE_MAPPINGS.key?(corrected[:permit_type])
      corrected[:permit_type] = PERMIT_TYPE_MAPPINGS[corrected[:permit_type]]
    end
    
    corrected
  end
end