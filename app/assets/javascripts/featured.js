// work-around turbo links to trigger ready function stuff on every page.

var featured_ready;
featured_ready = function () {

    // Initialize the jQuery File Upload widget:
    $('.featuredform').fileupload({

            downloadTemplate: null,
            downloadTemplateId: null,
            uploadTemplate: null,
            uploadTemplateId: null,

            add: function (e, data) {
                return data.submit();
            },

            downloadTemplate: function (o) {

                var file = o.files[0];

                if(file.error){
                    $('.featured-photo').html("<div>Error uploading photo.</div>")
                } else {
                    $('.featured-photo').html('<img src="' + file.image_url + '" alt="Featured Researcher Photo">')
                }
            }

        }
    );

}

$(document).ready(featured_ready);
$(document).on('page:load', featured_ready);
