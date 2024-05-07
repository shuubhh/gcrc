$(document).ready(function(){

    $('#menu').click(function(){
      $(this).toggleClass('fa-times');
      $('header').toggleClass('toggle');
    });
  
    $(window).on('scroll load',function(){
  
      $('#menu').removeClass('fa-times');
      $('header').removeClass('toggle');
  
      if($(window).scrollTop() > 0){
        $('.top').show();
      }else{
        $('.top').hide();
      }
  
    });
  
    // smooth scrolling 
  
    $('a[href*="#"]').on('click',function(e){
  
      e.preventDefault();
  
      $('html, body').animate({
  
        scrollTop : $($(this).attr('href')).offset().top,
  
      },
        500, 
        'linear'
      );
  
    });


    fetch('https://apii-gateway-7e28ml3y.uc.gateway.dev')
    .then(response => response.json())
    .then(data => {
        const value = data.value;
        const visitorNumberElement = document.getElementById('visitor-number');
        if (visitorNumberElement) {
            // Set the text content of the element instead of innerHTML
            visitorNumberElement.textContent = value;
        }
    });

  
/*
  // GET request to API
  fetch('https://apii-gateway-7e28ml3y.uc.gateway.dev')
    .then(response => response.json())
    .then(data => {
      // Get the value from the response and display it on the website
      const value = data.value;
      document.getElementById('visitor-number').innerHTML = value;
    });
  
  
  });
  */