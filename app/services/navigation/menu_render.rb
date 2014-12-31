module Navigation
  class MenuRender < Navigation::Render::Base
    def render(***REMOVED***s)
      render_***REMOVED***s(***REMOVED***s)
    end

    protected

    def render_***REMOVED***s(***REMOVED***s, html_options = {})
      content_tag :ul, html_options do
        html = ***REMOVED***s.map do |***REMOVED***|
          render_***REMOVED***(***REMOVED***)
        end.join(" ")

        raw html
      end
    end

    def render_***REMOVED***(***REMOVED***)
      has_sub***REMOVED***s = ***REMOVED***[:subnodes].any?

      can_show = if ***REMOVED***[:visible]
                   true
                 elsif has_sub***REMOVED***s
                   has_visible_sub***REMOVED***s?(***REMOVED***[:subnodes])
                 else
                   can_show?(***REMOVED***[:type])
                 end

      if can_show
        content_tag :li, :class => ***REMOVED***[:css_class].join(" ") do
          li = []
          ***REMOVED***_path = path_method ***REMOVED***[:path]

          li << link_to(***REMOVED***_path) do
            link = []
            link_content = I18n.t(***REMOVED***[:type], :scope => :navigation)

            if ***REMOVED***[:icon]
              link << content_tag(:i, "", :class => "fa fa-lg fa-fw #{***REMOVED***[:icon]}")
            end

            link << content_tag(:span, link_content, :class => "***REMOVED***-item-parent")

            raw link.join(" ")
          end

          if has_sub***REMOVED***s
            options = {}

            options[:style] = "display: block;" if ***REMOVED***[:css_class].include?(:open)

            li << render_***REMOVED***s(***REMOVED***[:subnodes], options)
          end

          raw li.join(" ")
        end
      else
        ""
      end
    end

    def has_visible_sub***REMOVED***s?(subnodes)
      subnodes.any? do |node|
        can_show?(node[:type])
      end
    end

    def can_show?(feature)
      policy(feature).index?
    end

    def policy(feature)
      klass = feature.singularize.camelcase.constantize

      begin
        Pundit::PolicyFinder.new(klass).policy!.new(current_user, klass)
      rescue
        ApplicationPolicy.new(current_user, klass)
      end
    end
  end
end