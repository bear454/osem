# frozen_string_literal: true

require 'open-uri'

class TicketPdf < Prawn::Document
  include FormatHelper

  VERSION = '5'
  MARGIN = 36 # 36/72 pt : half an inch
  def initialize(conference, user, physical_ticket, ticket_layout, file_name)
    super(
      page_layout: ticket_layout,
      page_size:   'LETTER',
      margin:      MARGIN,
      filename:    file_name
    )
    font_families.update(
      "Arvo" => {
        bold: Rails.root.join('app', 'assets', 'fonts', 'Arvo-Bold.ttf')
      },
      "Open Sans" => {
        normal:      Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Regular.ttf'),
        italic:      Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Italic.ttf'),
        bold:        Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Bold.ttf'),
        bold_italic: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-BoldItalic.ttf')
      }
    )
    stroke_color 'C0C0C0'

    @user = user
    @conference = conference
    @physical_ticket = physical_ticket
    @registration_ticket = user.physical_registration_ticket_for(conference)
    @ribbons = user.badge_ribbons_for(conference)

    @left = bounds.left
    @right = bounds.right
    @top = bounds.top
    @bottom = bounds.bottom
    @mid_vertical = (bounds.top - bounds.bottom) / 2
    @mid_horizontal = (bounds.right - bounds.left) / 2
    @x = 0
    @image_path = Rails.root.join('app', 'assets', 'images')

    # stroke_axis
    # page is layed out in 1/4s :
    # +---+---+
    # | 1 | 2 |
    # +---+---+
    # | 3 | 4 |
    # +---+---+
    draw_first_square
    draw_second_square
    draw_third_square
    draw_fourth_square
    draw_fold_lines
  end

  def draw_first_square
    bounding_box([@left, @top],
      width:  (@mid_horizontal - MARGIN),
      height: @mid_vertical
    ) do
      # stroke_axis
      logo_block([bounds.left, bounds.top])
      # bounding_box([bounds.left, bounds.top],
      #   width:  bounds.width,
      #   height: 52
      # ) do
      #   font('Arvo', style: :bold) do
      #     text_box(@conference.title, size: 21, align: :center)
      #   end
      #   font('Courier') do
      #     text_box('https://lfnw.org', size: 8, align: :center, valign: :bottom)
      #   end
      #   # stroke_bounds
      # end
      image(@image_path.join('treeline.png'),
        fit: [bounds.width, 36], position: :center
      )
      bounding_box([18, bounds.height - 86],
        width: (bounds.width - 36), height: (bounds.height - 154)
      ) do
        font('Open Sans') do
          text(@user.name.to_s,
            size: 18, align: :center, style: :bold, disable_wrap_by_char: true
          )
          unless @user.nickname.blank?
            text("“#{@user.nickname}”",
              size: 12, align: :center, style: :italic, disable_wrap_by_char: true
            )
          end
          move_down(8)
          text(@user.affiliation.to_s,
            size: 14, align: :center, disable_wrap_by_char: true,
            overflow: :shrink_to_fit
          )
        end
        # stroke_bounds
      end
      @ribbons.each_with_index do |ribbon, index|
        at_height = (@ribbons.length - 1 - index) * 24 + 100
        badge_marker(ribbon, at_height)
      end
      image(@image_path.join('btc_horizontallogo_web.png'),
        fit: [bounds.width, bounds.height], vposition: :bottom)
    end
  end

  def draw_second_square
    bounding_box([@mid_horizontal + MARGIN, @top],
      width: (@mid_horizontal - MARGIN),
      height: @mid_vertical
    ) do
      # registration QR code
      bounding_box([bounds.left, bounds.top],
        width:  bounds.width,
        height: (bounds.height - MARGIN) / 3
      ) do
        stroke_color 'c0c0c0'
        stroke do
          rounded_rectangle([bounds.left, bounds.top], bounds.width, bounds.height, 18)
        end
        if @registration_ticket
          text_box('Check-In',
            at: [bounds.left + 9, bounds.top - 18],
            size: 12, align: :center,
            width: bounds.width - bounds.height - 18
          )
          bounding_box([(bounds.width - bounds.height- 36) / 2, (bounds.height - 36) / 2 + 36], width: 36, height: 36) do
            icon 'fa-sign-in', size: 36
          end
          print_qr_code("https://#{ENV['OSEM_HOSTNAME']}/admin/scan_ticket/#{@registration_ticket}",
            pos: [bounds.right - bounds.height + 9, bounds.top - 9],
            extent: bounds.height - 18,
            stroke: false,
            level: :h
          )
        else
          text("You need a registration ticket! https://#{ENV['OSEM_HOSTNAME']}/conferences/#{@conference.short_title}/register")
        end
      end
      # logo
      logo_block([bounds.left, (bounds.height + 52 + MARGIN) / 2])
      # MECARD
      bounding_box([bounds.left, (bounds.height - MARGIN) / 3 + MARGIN],
        width:  bounds.width,
        height: (bounds.height - MARGIN) / 3
      ) do
        stroke_color 'c0c0c0'
        stroke do
          rounded_rectangle([bounds.left, bounds.top], bounds.width, bounds.height, 18)
        end
        text_box('Name & email',
          at: [bounds.left + 9, bounds.top - 18],
          size: 12, align: :center,
          width: bounds.width - bounds.height - 18
        )
        bounding_box([(bounds.width - bounds.height- 36) / 2, (bounds.height - 36) / 2 + 36], width: 36, height: 36) do
          icon 'fa-user', size: 36
        end
        print_qr_code(@user.mecard,
          pos: [bounds.right - bounds.height + 9, bounds.top - 9],
          extent: bounds.height - 18,
          stroke: false,
          level: :h
        )
      end
      font('Courier') do
        text_box("v#{VERSION}",
          align: :right, valign: :bottom,
          size: 6
        )
      end
      # stroke_bounds
    end
  end

  def draw_third_square
    bounding_box([@left, @mid_vertical],
      width: (@mid_horizontal - MARGIN),
      height: @mid_vertical
    ) do
      image(@image_path.join('folding-instructions.png'), at: [bounds.left, bounds.top - 18], width: bounds.width)
      # stroke_bounds
    end
  end

  def draw_fourth_square
    bounding_box([@mid_horizontal + MARGIN, @mid_vertical],
      width: (@mid_horizontal - MARGIN),
      height: @mid_vertical
    ) do
      font('Arvo', style: :bold) do
        text_box('Code of Conduct',
          at: [bounds.left, bounds.top], height: MARGIN,
          size: 12, align: :center, valign: :center
        )
      end
      text_box(markdown(@conference.code_of_conduct).gsub(/<\/?p>/, ''),
        at: [bounds.left, bounds.top - MARGIN],
        align: :justify, inline_format: true, overflow: :shrink_to_fit
      )
      # stroke_bounds
    end
  end

  def draw_fold_lines
    stroke_color 'C0C0C0'
    dash(2, space: 2)
    stroke_line([0, @mid_vertical], [bounds.width, @mid_vertical])
    stroke_line([@mid_horizontal, 0], [@mid_horizontal, bounds.height])
    dash(2, space: 0)
  end

  def logo_block(at)
    bounding_box(at,
      width:  bounds.width,
      height: 52
    ) do
      font('Arvo', style: :bold) do
        text_box(@conference.title,
          size: 21, align: :center
        )
      end
      font('Courier') do
        text_box('https://' + ENV['OSEM_HOSTNAME'],
          size: 8, align: :center, valign: :bottom
        )
      end
      # stroke_bounds
    end
  end

  def badge_marker(label, top, options = {})
    banner_height = 20
    inset = 4
    margin = 2

    fill_color(options[:banner_color] || '000000')

    bounding_box([(bounds.width * 0.2), top], width: (bounds.width * 0.8), height: banner_height) do
      fill_polygon(
        [0, 0],
        [bounds.width, 0],
        [bounds.width, bounds.height],
        [0, bounds.height],
        [inset, (bounds.height / 2)]
      )
      fill_color(options[:text_color] || 'ffffff')
      text_box(label, align: :center, valign: :center, at: [(inset + margin), (bounds.height - margin)], width: (bounds.width - inset - margin * 2), height: (bounds.height - margin * 2), overflow: :shrink_to_fit, size: (bounds.height - margin * 2), style: :italic)
      # reset
      fill_color '000000'
    end
  end
end
