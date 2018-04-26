prawn_document(page_size: 'LETTER', margin: 36) do |pdf|
  header = %w(Name Email Answer)
  table_data = @registrations.collect do |registration|
    user = registration.user
    [
      (user.name.present? ? user.name : user.username),
      user.email,
      registration.qanswers.first.answer.title
    ]
  end

  pdf.text @conference.title, font_size: 24
  if @answer.present?
    pdf.text "Answered \"#{@answer.title}\" to Question \"#{@question.title}\""
  else
    pdf.text "Answers to Question \"#{@question.title}\""
  end
  pdf.table [header, *table_data], header: true, width: 540,
    cell_style: { border_lines: [ :dotted, :solid, :dotted, :solid ] }
end
