/* window.vala
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
  [GtkTemplate (ui = "/org/gnome/gitlab/HelpDev/window.ui")]
  public class Window : Adw.ApplicationWindow {

    [GtkChild]
    private unowned Browser browser;

    public Window (Gtk.Application app) {
      Object (application: app);
    }

    construct {
      var settings = new Settings ("org.gnome.gitlab.HelpDev");

      // update the settings when the properties change and vice versa
      settings.bind ("width", this, "default-width", SettingsBindFlags.DEFAULT);
      settings.bind ("height", this, "default-height", SettingsBindFlags.DEFAULT);
      settings.bind ("is-maximized", this, "maximized", SettingsBindFlags.DEFAULT);
      settings.bind ("is-fullscreen", this, "fullscreened", SettingsBindFlags.DEFAULT);
    }

    [GtkCallback]
    private void on_link_clicked (string uri) {
      browser.web_view.load_uri (uri);
    }

    [GtkCallback]
    private void on_browser_back () {
      browser.web_view.go_back ();
    }

    [GtkCallback]
    private void on_browser_forward () {
      browser.web_view.go_forward ();
    }
  }
}
