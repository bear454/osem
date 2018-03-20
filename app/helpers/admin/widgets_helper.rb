module Admin
  module WidgetsHelper
    # DRY up rendering of visual elements

    def big_statistic(icon, subtitle, value, delta, reverse_delta = false)
      content_tag('div', class: 'dashbox text-center') do
        content_tag('span', class: 'fa') do
          fa_icon(icon) +
          value.to_s.html_safe
        end +
        content_tag('p') do
          content_tag('small', subtitle.pluralize(value)) +
          '&nbsp;'.html_safe +
          login_delta_label(delta, reverse_delta)
        end
      end
    end


    def login_delta_label(delta, reverse = false)
      variant = case
      when delta.to_i > 0 then
        reverse ? :warning : :success
      when delta.to_i < 0 then
        reverse ? :success : :warning
      else
        :info
      end
      bootstrap_label(
        sprintf("%+d", delta.to_i),
        variant,
        title: "#{delta} since you last logged in"
      )
    end
  end
end
