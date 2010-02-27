if RUBY_VERSION < "1.9"
  $KCODE = 'u'
  require 'jcode'
end

class Achoo; end

class Achoo::Term

  def self.bold(text)
    "\e[1m#{text}\e[0m"
  end

  def self.underline(text)
    "\e[4m#{text}\e[0m"
  end

  def self.password
    `stty -echo`
    pas = ask('Password')
    `stty echo`
    pas
  end

  def self.ask(question='')
    answer = nil
    loop do
      print bold("#{question}> ")
      $stdout.flush
      answer = gets.chop
      unless $stdin.tty?
        puts answer
      end
      break unless a_little_something(answer)
    end
    answer
  end

  def self.menu(question, entries, special=nil, additional_valid_answers=[])
    print_menu(entries, special)
    return '1' if entries.length == 1 && special.nil?

    valid_answers = {}
    valid_answers['0'] = true unless special.nil?
    1.upto(entries.length).each {|i| valid_answers[i.to_s] = true}
    additional_valid_answers.each {|a| valid_answers[a] = true}

    answer = nil
    while true
      answer = ask question
      if valid_answers[answer]
        break
      else
        puts "Invalid value. Must be one of " << valid_answers.keys.sort.join(',')
      end
    end

    answer
  end

  def self.table(headers, data_rows, summaries=nil)
    lengths   = calculate_table_cell_widths(headers, data_rows)
    separator = table_separator(lengths)
    format    = build_format(data_rows, lengths)
    
    center_table_headers(headers, lengths)

    puts separator
    print '| ' << headers.join(' | ') << " |\n"
    puts separator
    data_rows.each {|r| printf format, *r }
    puts separator
    unless summaries.nil? || data_rows.length == 1
      printf format, *summaries
      puts separator
    end
  end

  private

  def self.center_table_headers(headers, lengths)
    lengths.each_with_index do |len,i|
      headers[i] = headers[i].center(len)
    end
  end

  def self.print_menu(entries, special)
    max_digits = Math.log10(entries.length).to_i
    format = "% #{max_digits}d. %s\n"
    entries.each_with_index do |entry, i|
      printf format, i+1, entry
    end
    printf format, 0, special unless special.nil?
  end

  def self.calculate_table_cell_widths(headers, data_rows)
    lengths = []
    headers.each_with_index do |h, i|
      lengths[i] = RUBY_VERSION < '1.9' ? h.jlength : h.length
    end
    data_rows.each do |r|
      r.each_with_index do |d, i|
        len = RUBY_VERSION < '1.9' ? d.jlength : d.length
        lengths[i] = [len, lengths[i]].max
      end
    end
    lengths
  end

  def self.build_format(data_rows, lengths)
    is_column_left_justified = Array.new(lengths.nitems)
    is_column_left_justified.fill(false)
    
    data_rows.each do |r|
      r.each_index do |c|
        if !r[c].strip.empty? && !r[c].match(/^\d+[:.,]?\d*$/)
          is_column_left_justified[c] = true
        end
      end
    end

    lengths.reduce('|') do |f, l|
      justify = is_column_left_justified.shift ? '-' : ''
      f + " %#{justify}#{l}s |"
    end + "\n"
  end

  def self.table_separator(lengths)
    lengths.reduce('+') {|s, length| s + '-'*(length+2) + '+'}
  end

  def self.a_little_something(answer)
    case answer.downcase
    when 'bless you!', 'gesundheit!'
      puts "Thank you!"
      return true
    else
      return false
    end
  end

end
