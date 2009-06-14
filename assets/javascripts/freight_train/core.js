/* Observer: this awesome class is described by The Grubbsian
   http://www.thegrubbsian.com/?p=100 */

var Observer = (function(){
  var Observation = function(name, func) {
    this.name = name;
    this.func = func;
  };
  var constructor = function() {
    this.observations = [];
  };
  constructor.prototype = {
    observe: function(name, func) {
      var exists = this.observations.findAll(function(i) {
        return (i.name==name) && (i.func==func); }).length > 0;
      if(!exists) { this.observations.push(new Observation(name, func)); }
    },
    unobserve: function(name, func) {
      this.observations.remove(function(i) { return (i.name==name) && (i.func==func); });
    },
    fire: function(name, data, scope) {
      if(!(data instanceof Array)) data = [data];
      var funcs = this.observations.findAll(function(i) { return (i.name==name); });
      funcs.forEach(function(i) { i.func.apply(scope, data); });
    }
  };
  return constructor;    
})();


/* InlineEditor */

var InlineEditor = (function(){
  var CURRENT_ROW_ID = null;
  var observer = new Observer();

  //var constructor = function(url, tr, editor_writer, before_init, after_init) {
  var constructor = function(url, tr, editor_writer) {
    tr = $(tr);
    if(!tr) return;

    // if you click a row, switch to its editor
    tr.observe('click',function(event) {

      // close any existing editors
      InlineEditor.close();

      // before_init callback can return false to cancel the edit
      //if(before_init)
      //  if(!before_init(tr))
      //    return;
      observer.fire('before_init', tr);

      // Find relevant tags
      var form = tr.up('.freight_train'); /*$('the_form');*/ if(!form) return;

      // Get properties
      var id = tr.readAttribute('id');
      var editor_html = editor_writer(tr); if(!editor_html) return;	
      //var row_class = tr.hasClassName('alt') ? 'row editor alt' : 'row editor'				

      // Configure form
      form.onsubmit = function() {
        FT.xhr(url, 'put', Form.serialize(form));
        return false;
      };

      // Hide the view-only row	 
      tr.hide();



      // METHOD A: Firefox 3 strips table tags out of html at tr_edit.update(html)
      /*
      // Generate extra row
      var tr_extra = $(document.createElement('tr'));
      tr_extra.className = 'row';
      tr_extra.setAttribute('id', 'extra_row');
      tr_extra.setStyle({'display':'none'});

      // Generate editor row
      var tr_edit = $(document.createElement('tr'));
      tr_edit.className = 'row editor';
      //tr_edit.setAttribute('id', id + '_edit');
      tr_edit.setAttribute('id', 'edit_row');
      var html = editor_html + 
        '<td class="last-child">' +
          //'<input id="tag_submit" name="commit" type="submit" value="Save" />' +
          '<button id="tag_submit" name="commit" type="submit">Save</button>' +
          '<button onclick="InlineEditor.close();return false;">Cancel</button>' +
        '</td>';
      //alert(html);
      tr_edit.update(html);

      // Insert the editor row (using the DOM)
      var parent = tr.parentNode;
      var nextSibling = tr.nextSibling;
      nextSibling ? parent.insertBefore(tr_edit,nextSibling) : parent.FTendChild(tr_edit);

      // Add an even number of hidden rows to keep alternating CSS consistent
      parent.insertBefore(tr_extra,tr_edit);
      //*/



      // METHOD B: In Chrome 2, after the table is updated, lines jump to the top of the list
      ///*
      // Generate html of extra row and editable row
      // Add an even number of hidden rows to keep alternating CSS consistent
      html =
        //'<tr class="row" id="' + id + '_extra" style="display:none;"></tr>' +
        '<tr class="row editor" id="edit_row">' +
          editor_html + 
          '<td class="last-child">' +
            //'<input id="tag_submit" name="commit" type="submit" value="Save" />' +
            '<button id="tag_submit" name="commit" type="submit">Save</button>' +
            '<button onclick="InlineEditor.close();return false;">Cancel</button>' +
          '</td>' +
        '</tr>';

      // Insert the html (IE7 fails when inserting TR objects this way; works to insert HTML string)
      tr.insert( {'after': html} );
      var tr_edit = $('edit_row');
      //*/

      // 
      FT.submit_forms_on_enter(tr_edit);

      // after_init callback
      //if(after_init) after_init(tr,tr_edit);
      observer.fire("after_init", [tr, tr_edit]);

      // Set the current row being edited
      CURRENT_ROW_ID = id;
    });
  };

  // Class methods
  constructor.close = function() {
    if(CURRENT_ROW_ID) {
      var id = CURRENT_ROW_ID;
      var e;
      e = $('extra_row'); 	if(e) e.remove();
      e = $('edit_row');  	if(e) e.remove();
      e = $(id);          	if(e) e.show();
      //e = $('edit_errors'); if(e) e.hide();
      e = $('error');       if(e) e.hide();
      CURRENT_ROW_ID = null;
    }
  };

  // Class events
  constructor.observe = function(name,func){observer.observe(name,func);};
  constructor.unobserve = function(name,func){observer.unobserve(name,func);};

  // Listen for the escape key
  document.observe('dom:loaded', function() {
    document.observe('keyup', function(event) {
      if(CURRENT_ROW_ID && (event.keyCode==Event.KEY_ESC))
        InlineEditor.close();
    });
  });

  return constructor;  
})();


/* FT */

var FT = (function(){

  /* PRIVATE VARIABLES */
  var token = '';
  var enable_date_selection = false;
  var enable_nested_records = false;
  var observer = new Observer();
  
  /* PRIVATE METHODS */
  var render_deleted = function(id) {
    // make the item unresponsive to clicks and remove its background color
    var e=$(id);
    if(e) {
      e.addClassName('deleted');
      e.removeClassName('editable');
      e.stopObserving('mouseover');
      FT.set_background_color(e.down('.tag-color'),'');
      FT.set_background_color(e.down('.tag-bubble'),'');
      e.select('input').each(function(i) {
        i.disabled = true;
      });
    }
  };
  var _hookup_row = function(model, row) {
    if(row.hasClassName('interactive')) FT.hover_row(row);
    model.hookup_row(row);
  };
  
  /* */
  InlineEditor.observe('before_init',function(tr) {
    var e=$('error');
    if(e) e.hide();
  });
  
  /* PUBLIC METHODS */
  return {
    init: function(args) {
      args = args || {};
      if(args.token) token = args.token;
      if(args.enable_date_selection) enable_date_selection = true;
      if(args.enable_nested_records) enable_nested_records = true;      
      document.observe('dom:loaded', function() {
        FT.hookup();
        observer.fire('load');
      });
    },
    observe: function(name, func) { observer.observe(name, func); },
    unobserve: function(name, func) { observer.unobserve(name, func); },
    
    /* I don't know if I like making this a public method here: it's a callback for the server */
    on_created: function() {
      observer.fire('created');
    },
    
    hookup_form: function(form) {
      if(!form) throw new Error('form must not be null');
      var add_row=form.down('#add_row');
      if(add_row) {
        FT.set_add_command_on_click(form,add_row);
        FT.hookup_editor(add_row);
      //}else{
        //alert('\"add_row\" not found');
      }
    },
    hookup_editor: function(editor) {
      if(!editor) throw new Error('editor must not be null');
      FT.submit_forms_on_enter(editor);
      if(enable_date_selection)
        FT.enable_date_selection(editor);
      if(enable_nested_records)
        FT.reset_add_remove_for_all(editor);
    },
    hookup: function() {
      $$('.freight_train').each(function(train) {
        FT.hookup_form(train);
        var model_name = train.readAttribute('model')
        var model = FT[model_name];
        if(model && model.hookup_row)
          train.select('.row').each(function(row){_hookup_row(model,row);});
      });
      // do this for the whole page (might Apply to commands area)
      if(enable_date_selection)
        FT.enable_date_selection();
    },
    hookup_row: function(model_name, row) {
      if(!model_name) throw new Error('model_name must not be null');
      if(!row) throw new Error('row must not be null');
      var model = FT[model_name];
      if(model && model.hookup_row)
        _hookup_row(model, row);
    },
    destroy: function(msg,id,path) {
      if(confirm(msg)) {
        render_deleted(id);
        FT.xhr(path,'delete');
      }
      Event.stop(window.event);
    },
    xhr: function(url,method,params,args) {
      args = args || {};
      args.asynchronous = true;
      args.evalScripts = true;
      args.method = method;
      args.parameters = token || "";
      if(params) args.parameters += '&' + params;
      new Ajax.Request(url, args);
    },
    delete_record: function(id) {
      FT.safe_remove(id);
      FT.restripe_rows();
    },
    restripe_rows: function() {
      var rows = $$('tbody > tr.row');
      //alert(rows[0].readAttribute('style'));
      var alt = false;
      for(var i=0; i<rows.length; i++)
      {
        if(alt != rows[i].hasClassName('alt'))
        {
          if(alt)
            rows[i].addClassName('alt');
          else    
            rows[i].removeClassName('alt');
        }
        alt = !alt;
      }
    },    
    hover_row: function(row) {
      if(!row) throw new Error('row must not be null');
      // 2009.03.27 - Both of the following methods fail to add the
      // 'hovered' class to a row that has just been edited or created.
      //$$('.row.interactive').each( function(e) {
      row.observe('mouseover', function() {
        //var e2 = $(e.readAttribute('id') + '_commands'); if(e2) e2.setStyle({visibility:'visible'});
        row.addClassName('hovered');
      });
      row.observe('mouseout', function() {
        //var e2 = $(e.readAttribute('id') + '_commands'); if(e2) e2.setStyle({visibility:'hidden'});
        row.removeClassName('hovered');
      });
      //});
      /*	
      e.hover(function()
      {
        // Show commands (if FTlicable)		
        var e2 = $(e.readAttribute('id') + '_commands'); if(e2) e2.show();
 
        // Add hovered style
        e.addClassName('hovered');
      }, function()
      {
        // Hide commands (if FTlicable)
        var e2 = $(e.readAttribute('id') + '_commands'); if(e2) e2.hide();
 
        // Remove hovered style
        e.removeClassName('hovered');
      }) });
      */
    },
    edit_row_inline: function(row, url_root, editor_writer, before_edit, after_edit) {
      var id = row.readAttribute("id");
      var idn = id.match(/\d+/);
      var url = url_root + '/' + idn;
      new InlineEditor(url, row, editor_writer, before_edit, after_edit);
    }, 
    edit_row: function(row, url_root) {
      row.observe(
        "click",
        function(event) {
        var id = row.readAttribute("id");
        var idn = id.match(/\d+/);
        var url = url_root + '/' + idn; // + "/edit"
        window.location = url;
        });
    }, 
    submit_forms_on_enter: function(parent) {
      // Create the handler only once, no matter how often this method is called
      if(!FT.submit_forms_on_enter.keypress)
        FT.submit_forms_on_enter.keypress = function(event) {
          if(event.keyCode == Event.KEY_RETURN) {
            Event.stop(event);
            var e = Event.element(event);										if(!e) return;
            //alert("event element"); e.setStyle({border:'Solid 2px Red'});
            var tr = e.up("tr");														if(!tr) return;
            //alert("tr"); tr.setStyle({border:'Solid 2px Red'});
            var submit = tr.down("*[type='submit']");		    if(!submit) return;
            //alert("submit"); submit.setStyle({border:'Solid 2px Red'});
            // Works in Chrome 2, IE 7, Firefox 3
            submit.click();
          }
        };
 
      var selector = function(x){ return parent ? parent.select(x) : $$(x); };
      selector('input, select').each(function(e) {
        // Register the event handler only once per input element, no matter how often this method is called
        e.stopObserving("keypress", FT.submit_forms_on_enter.keypress);
        e.observe("keypress", FT.submit_forms_on_enter.keypress);
      });
    }, 
    set_add_command_on_click: function(form, add_row) {
      if(!form) throw new Error('form must not be null');
      //form = form || $('form');                 if(!form) return;
      add_row = add_row || form.down('#add_row');           if(!add_row) return;
      var submit = add_row.down('input[type=\"submit\"]');  if(!submit) return;
      submit.observe('click', function(click_event) {
        form.onsubmit = function(submit_event) {
          //alert(form.action);
          FT.xhr(form.action,'post',form.serialize());
          return false;
        };
      });
    },
    // todo: move to Select or HTMLSelectElement?
    select_value: function(selector,value) {
      if(!selector) {
        alert("selector not found");
        return;
      }
      if(!value) {
        alert("value not found");
        return;
      }
      //alert(value);
      var options = selector.options;
      var option;
      for(var i=0;i<options.length;i++) {
        option = options[i];
        if(option.value == value) {
          option.selected = true;
          return;
        }
      }
    },
    
    /* ARE THESE NEXT TWO STRICTLY FREIGHT TRAIN? */
    copy_selected_value: function(tr,tr_edit,attr_name,method) {
      var e=tr.down('*[attr="'+attr_name+'"]');
      var sel=tr_edit.down('#'+method);
      if(e && sel)
        FT.select_value(sel,e.readAttribute('value'));
      else {
        if(!e) alert(attr_name+' not found');
        if(!sel) alert('selector "'+method+'" ('+attr_name+') not found');
      }
    },
    check_selected_values: function(tr,tr_edit,attr_name) {
      var e=tr.down('*[attr="'+attr_name+'"]');
      if(e) {
        var values=e.readAttribute('value').split('|');
        for(var i=0; i<values.length; i++)
        {
          e=tr_edit.down('*[value="'+values[i]+'"]');
          if(!e) alert('"'+values[i]+'" not found');
          else e.writeAttribute('checked','checked');
        }
      }
      else
        alert(attr_name+' not found');
    },
    
    add_nested_object: function(sender) {
      var tr = $(sender).up('tr'); if(!tr) return;
      var table = tr.up('table.nested'); if(!table) return;
      var new_tr = tr.cloneNode(true);
      table.appendChild(new_tr);
      FT.reset_add_remove_for(table);
    }, 
    reset_nested: function(table) {
      if(table) {
        var nested = table.select('tr');
        for(var i=1;i<nested.length;i++) {
          nested[i].remove();
          FT.reset_add_remove_for(table);
        }
      }
    }, 
    delete_nested_object: function(sender) {
      var tr = $(sender).up('tr'); if(!tr) return;
      var table = tr.up('table.nested'); if(!table) return;
      tr.remove();
      FT.reset_add_remove_for(table);
    }, 
    reset_add_remove_for_all: function(parent) {
      var selector = function(x){ return parent ? parent.select(x) : $$(x); };
      selector('table.nested.editor').each(FT.reset_add_remove_for);
    }, 
    reset_add_remove_for: function(table) {
      var reset_nested_row = function(row,object_name,i,delete_visibility,add_visibility) {
        row.select('.field').each(function(e){
          e.writeAttribute('name',object_name+'['+i+']['+e.id+']');
        });
        var delete_link = row.down('.delete-link');
        if(delete_link) delete_link.setStyle({visibility:delete_visibility});
        var add_link = row.down('.add-link');
        if(add_link) add_link.setStyle({visibility:add_visibility});
      };
 
      var object_name=table.readAttribute('name');
      var rows=table.select('tr');
      var n=rows.length-1;
      if(n>0) {
        for(var i=0; i<n; i++) {
          reset_nested_row(rows[i],object_name,i,'visible','hidden');
        }
        reset_nested_row(rows[n],object_name,n,'visible','visible');
      }
      else if(n==0) {
        reset_nested_row(rows[0],object_name,0,'hidden','visible');
      }
 
      observer.fire('after_reset_nested',table);
      //if(window.after_reset_nested) window.after_reset_nested(table);
    },
    
    /* SHOULD THIS GET A BETTER NAME OR BE PUT IN A SUB-NAMESPACE? */     
    for_each_row: function(root_tr,root_tr_edit,root_tr_selector,root_tr_edit_selector,fn) {
      var nested_rows=root_tr.select(root_tr_selector);
      var nested_editor_rows=root_tr_edit.select(root_tr_edit_selector);
      for(var i=0; i<nested_rows.length; i++)
      {
        var tr=nested_rows[i];
        var tr_edit=nested_editor_rows[i];
        fn(tr,tr_edit);
      }
    }

  };
})();



/* MOVE THESE OUT OF FREIGHT TRAIN */
FT.safe_remove = function(id) {
  var e=$(id); if(e) e.remove();
};

FT.enable_date_selection = function(parent) {
  var selector = function(x){ return parent ? parent.select(x) : $$(x); };
  selector('.date-field').each(function(field) {
    new DateSelector(field, function(dateText) {
      field.writeAttribute('value', dateText);
    });
  });
};

FT.auto_total = function(context,attr,prefix) {
  context = $(context);
  if(context) {
   var total=context.down('#total');
    // This is not very efficient!
    while(!total) {
      context=context.up(1);
      if(!context) return;
      total=context.down('#total');
    }

    //if(total) {
      var amounts = context.select('#'+attr);
      //alert(amounts.length);
      var amount;
      var resum = function() {
        var sum=0;
        var n;
        for(var i=0; i<amounts.length; i++) {
          amount=amounts[i];
          n = parseFloat(amount.value.replace(/,/,''));
          if(!isNaN(n)) sum += n; // else alert("nan");
        }
        total.value = "$" + sum.toFixed(2);
        //if(prefix)
        //  total.value = prefix + sum.toFixed(2);
        //else
        //  total.value = sum.toFixed(2);
      }
      for(var i=0; i<amounts.length; i++) {
        var amount = amounts[i];
        amount.onchange=resum;
      }
      resum();
    //}
  }
};

FT.set_background_color = function(e, color) {
  e = $(e);
  //alert(id);
  //alert(color);
  //var e = $('tag_' + id + '_color');
  if(e) {
  //if(Prototype.Browser.IE)
    e.setStyle({'backgroundColor': color});
  //else
  //	e.setStyle('background-color', color);
  }
};

/* MOVE TO RJS */
FT.highlight = function(id) {
  new Effect.Highlight(id);
};