/* doc_list_model.vala
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

  /**
   * Get the URI by relative path.
   */
  string get_relative_uri (string base_link, string relative_path) {
    var tokens = relative_path.split ("#", 2);
    var anchor = "";
    if (tokens.length > 1) {
      relative_path = tokens[0];
      anchor = "#" + tokens[1];
    }
    return File.new_for_uri (base_link).get_parent ().resolve_relative_path (relative_path).get_uri () + anchor;
  }

  /**
   * The document item that used in sidebar.
   */
  public abstract class DocItem : Object {
    /**
     * The name of the item.
     */
    public string name { get; set; }

    /**
     * The flag indicate if the item is actionable.
     */
    public string link { get; set; }

    public abstract ListModel ? query_sub_items ();
  }

  /**
   * The Xml.Node-based document item.
   */
  public class XmlNodeDocItem : DocItem {
    protected Xml.Node* node;

    public XmlNodeDocItem (string name, string link, Xml.Node* node) {
      Object (name: name, link: link);
      this.node = node;
    }

    public override ListModel ? query_sub_items () {
      if (node->child_element_count () == 0) {
        return null;
      }
      return new XmlNodeDocListModel (link, node);
    }
  }

  /**
   * The base class to implement a list model.
   */
  public abstract class BaseDocListModel : Object, ListModel {
    protected GenericArray<DocItem> items = new GenericArray<DocItem> ();

    protected void add_item (DocItem item) {
      items.add (item);
      items_changed (items.length - 1, 0, 1);
    }

    public Object ? get_item (uint index) {
      return items[index];
    }

    public Type get_item_type () {
      return typeof (DocItem);
    }

    public uint get_n_items () {
      return items.length;
    }
  }

  public class XmlNodeDocListModel : BaseDocListModel {

    public XmlNodeDocListModel (string base_link, Xml.Node* node) {
      Object ();

      for (var itr = node->children; itr != null; itr = itr->next) {
        if (itr->type != Xml.ElementType.ELEMENT_NODE || itr->name != "sub") {
          continue;
        }
        var link = get_relative_uri (base_link, itr->get_prop ("link"));
        add_item (new XmlNodeDocItem (itr->get_prop ("name"), link, itr));
      }
    }
  }

  /**
   * A file-based async-loading base list model.
   */
  public abstract class BaseFileAsyncDocListModel : BaseDocListModel {

    public File? file { set; get; }

    public Error error { private set; get; }

    public bool loading { private set; get; }

    construct {
      this.notify["file"].connect (() => {
        this.do_load_from_file.begin ();
      });
    }

    private async void do_load_from_file (Cancellable? cancellable = null) {
      if (file == null) {
        return;
      }
      try {
        loading = true;
        yield load_from_file_async (cancellable);
      } catch (Error err) {
        warning ("failed to read files from %s: %s", file.get_path (), err.message);
        error = err;
      } finally {
        loading = false;
      }
    }

    protected abstract async void load_from_file_async (Cancellable? cancellable = null) throws Error;
  }

  /**
   * The document list model.
   */
  public class DirDocListModel : BaseFileAsyncDocListModel {

    public DirDocListModel (File? file = null) {
      Object (file : file);
    }

    protected override async void load_from_file_async (Cancellable? cancellable = null) throws Error {
      var enumerator = yield file.enumerate_children_async ("standard::*", FileQueryInfoFlags.NONE, Priority.DEFAULT,
        cancellable);

      FileInfo? file_info;
      while ((file_info = enumerator.next_file (cancellable)) != null) {
        var cur_file = file.resolve_relative_path (file_info.get_name ());
        var help_file = cur_file.resolve_relative_path (file_info.get_name () + ".devhelp2");
        if (help_file.query_exists (cancellable)) {
          var tree = Xml.Parser.parse_file (help_file.get_path ());
          var root = tree->get_root_element ();
          var title = root->get_prop ("title");
          var link = root->get_prop ("link");
          var link_uri = cur_file.resolve_relative_path (link).get_uri ();
          items.add (new XmlNodeDocItem (title, link_uri, root->first_element_child ()));
        }
      }

      items.sort ((a, b) => {
        return a.name > b.name ? 1 : a.name == b.name ? 0 : -1;
      });

      items_changed (0, 0, items.length);
    }
  }

  private string get_doc_dir () {
    var doc_dir = Environment.get_variable ("DOCDIR");
    if (doc_dir != null && doc_dir != "") {
      return doc_dir;
    }
    return "/usr/share/doc";
  }

  private ListModel ? create_navigation_model (Object? item) {
    var it = item as DocItem;
    if (it == null) {
      return new Gtk.SortListModel (new DirDocListModel (File.new_for_path (get_doc_dir ())),
                                    new Gtk.CustomSorter ((a, b) => {
                                      var a_item = a as DocItem;
                                      var b_item = b as DocItem;
                                      return a_item.name > b_item.name ? 1 : a_item.name == b_item.name ? 0 : -1;
                                    }));
    }
    return it.query_sub_items ();
  }
}
