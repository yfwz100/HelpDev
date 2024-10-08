/* browser.vala
 *
 * Copyright 2024 Zhi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Helpdev {

  public class Browser : Adw.Bin {

    public unowned WebKit.WebView web_view { private set; get; }

    public bool can_go_back { private set; get; }

    public bool can_go_forward { private set; get; }

    public Browser () {
      Object ();
    }

    protected override void constructed () {
      base.constructed ();

      var web_view = new WebKit.WebView () {
        settings = new WebKit.Settings () {
          allow_file_access_from_file_urls = true,
          allow_universal_access_from_file_urls = true,
          enable_javascript = true,
          enable_javascript_markup = true,
          javascript_can_access_clipboard = true,
          enable_developer_extras = true,
          disable_web_security = true
        },
      };
      web_view.set_background_color (Gdk.RGBA () { alpha = 0 });
      var stylesheet = new WebKit.UserStyleSheet (".devhelp-hidden { display: none; }",
                                                  WebKit.UserContentInjectedFrames.ALL_FRAMES,
                                                  WebKit.UserStyleLevel.USER, null, null);
      web_view.user_content_manager.add_style_sheet (stylesheet);
      web_view.load_changed.connect (() => {
        this.can_go_back = web_view.can_go_back ();
        this.can_go_forward = web_view.can_go_forward ();
      });

      this.child = this.web_view = web_view;
    }
  }
}
